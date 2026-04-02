import Foundation

struct ParsedTracker: Codable {
    var type: String = ""
    var amount: Double = 0
}

struct ParsedProblem: Codable {
    var title: String = ""
    var url: String = ""
    var technique: String = ""
    var resource: String = ""
    var isContest: Bool = false
    var date: String? = nil
}

struct ParsedContest: Codable {
    var name: String = ""
    var resource: String = ""
    var date: String? = nil
}

struct ParsedInput: Codable {
    var tracker: [ParsedTracker] = []
    var problems: [ParsedProblem] = []
    var contests: [ParsedContest]? = nil
    var summary: String = ""
}

enum AIService {

    private static let systemPrompt = """
    You are a productivity assistant. Parse the user's input into structured actions OR respond conversationally.

    Available tracker types (use these EXACT capitalized names):
    - Pushup (count)
    - Squat (count)
    - Water (milliliters, e.g. 500ml, 1L = 1000ml)
    - Run (miles, 1km = 0.621mi)
    - Problems (count of CP problems solved)
    - Calories (kcal)
    - Protein (grams)
    - Fat (grams)
    - Carbs (grams)

    Return ONLY valid JSON, no markdown, no explanation:
    {
      "tracker": [{"type": "Water", "amount": 1000}],
      "problems": [{"title": "Round 781 - A", "url": "https://codeforces.com/contest/781/problem/A", "technique": "greedy", "resource": "Codeforces", "isContest": false}],
      "contests": [{"name": "Codeforces Round 991", "resource": "Codeforces"}],
      "summary": "your response here"
    }

    Rules:
    - tracker.type MUST be one of: Pushup, Squat, Protein, Water, Run, Problems, Calories, Fat, Carbs (capitalized!)
    - Water is in ml (250ml, 500ml, 1L = 1000ml). Do NOT convert to cups.
    - Convert km to miles if needed

    FOOD / NUTRITION:
    - If user describes food they ate, estimate ALL macros and add tracker entries for Calories, Protein, Fat, Carbs
    - Also estimate and add Water if the food/drink contains significant liquid
    - Common estimates:
      - 1 egg: 78kcal, 6g protein, 5g fat, 1g carbs
      - chicken breast 100g: 165kcal, 31g protein, 3.6g fat, 0g carbs
      - rice 1 cup: 206kcal, 4g protein, 0g fat, 45g carbs
      - protein shake/scoop: 120kcal, 25g protein, 1g fat, 3g carbs
      - ramen bowl: 450kcal, 15g protein, 15g fat, 55g carbs
      - steak 200g: 500kcal, 50g protein, 30g fat, 0g carbs
      - salmon 150g: 280kcal, 30g protein, 17g fat, 0g carbs
      - bread slice: 80kcal, 3g protein, 1g fat, 15g carbs
    - Round to nearest 5. In summary, list the macro breakdown briefly.
    - If user only mentions protein specifically (e.g. "30g protein"), only add Protein.

    PROBLEMS (individual problem solves):
    - "solved https://codeforces.com/contest/2122/problem/D using dp" → add to problems with url, technique="dp", resource="Codeforces"
    - "did cf round X A-D" → 4 problems: "Round X - A" thru "Round X - D" with urls
    - Construct URLs when possible: codeforces.com/contest/X/problem/Y, leetcode.com/problems/slug, atcoder.jp/contests/X/tasks/Y
    - resource: Codeforces, Leetcode, CSES, AtCoder, USACO, Luogu, etc.
    - When problems are added, ALSO add tracker entry type "Problems" with count
    - Set isContest: false for problems
    - Include difficulty prefix in title: "D2. Tree Orientation (Hard Version)" for CF, "D - Forbidden Difference" for AtCoder
    - If user provides a URL, extract the problem letter/index from it for the title prefix
    - If you don't know the problem name from a URL, use the problem ID with the full URL (e.g. for luogu.com.cn/problem/P5424, title should be "P5424", url should be the full link)
    - NEVER truncate or shorten the problem name

    DATES:
    - If user says "on 3/15" or "yesterday" or a specific date, set the "date" field as "YYYY-MM-DD"
    - If no date mentioned, set date to null (today will be used)
    - Today is {today}

    CONTESTS (participated in a rated contest):
    - "did CF contest 1086" or "participated in weekly contest 478" → add to contests array
    - contests array is SEPARATE from problems. Use it when user says they DID a contest (participated).
    - You can add BOTH contests and problems if they say "did CF round 1086 solved A-D"
    - If user mentions a date, set date field

    GENERAL:
    - If input is NOT about tracking/problems/contests, return empty arrays and conversational summary
    - Keep summary short (1-2 sentences)
    """

    private static var resolvedPrompt: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return systemPrompt.replacingOccurrences(of: "{today}", with: fmt.string(from: .now))
    }

    static func parse(input: String, apiKey: String) async throws -> ParsedInput {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1000,
            "messages": [
                ["role": "user", "content": "\(resolvedPrompt)\n\nInput: \(input)"]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AIError.apiError("\(statusCode): \(body.prefix(500))")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw AIError.parseError("Could not extract text from API response")
        }

        let jsonString = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIError.parseError("Could not convert response to data")
        }

        let decoder = JSONDecoder()
        // Parse manually to handle missing fields gracefully
        guard let raw = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AIError.parseError("Response is not a JSON object")
        }

        var result = ParsedInput()
        result.summary = raw["summary"] as? String ?? ""

        if let trackerArr = raw["tracker"] as? [[String: Any]] {
            result.tracker = trackerArr.map { t in
                let amount = (t["amount"] as? NSNumber)?.doubleValue ?? 0
                return ParsedTracker(type: t["type"] as? String ?? "", amount: amount)
            }
        }

        if let probArr = raw["problems"] as? [[String: Any]] {
            result.problems = probArr.map { p in
                ParsedProblem(
                    title: p["title"] as? String ?? "",
                    url: p["url"] as? String ?? "",
                    technique: p["technique"] as? String ?? "",
                    resource: p["resource"] as? String ?? "",
                    isContest: p["isContest"] as? Bool ?? false,
                    date: p["date"] as? String
                )
            }
        }

        if let contArr = raw["contests"] as? [[String: Any]] {
            result.contests = contArr.map { c in
                ParsedContest(
                    name: c["name"] as? String ?? "",
                    resource: c["resource"] as? String ?? "",
                    date: c["date"] as? String
                )
            }
        }

        return result
    }

    enum AIError: LocalizedError {
        case apiError(String)
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .apiError(let msg): return msg
            case .parseError(let msg): return msg
            }
        }
    }
}

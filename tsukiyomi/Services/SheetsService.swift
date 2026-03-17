import Foundation

enum SheetsService {

    static func appendProblems(_ problems: [ParsedProblem]) async throws {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = fmt.string(from: .now)

        // Columns: Date | Problems (hyperlinked name) | Techniques | Notes | Resource
        let rows: [[String]] = problems.map { p in
            let date = p.date ?? today
            let col: String
            if p.url.isEmpty {
                col = p.title
            } else {
                let safeName = p.title.replacingOccurrences(of: "\"", with: "'")
                col = "=HYPERLINK(\"\(p.url)\", \"\(safeName)\")"
            }
            return [date, col, p.technique, "", p.resource]
        }

        try await post(rows: rows, sheet: "シート1")
    }

    static func appendContests(_ contests: [ParsedContest]) async throws {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = fmt.string(from: .now)

        // Columns: Date | Contest | Handle | Rank | Delta | Rating
        let rows: [[String]] = contests.map { c in
            let date = c.date ?? today
            return [date, c.name, "", "", "", ""]
        }

        try await post(rows: rows, sheet: "Contests")
    }

    private static func post(rows: [[String]], sheet: String) async throws {
        guard let urlString = UserDefaults.standard.string(forKey: "sheetsWebhookURL"),
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 10

        let body: [String: Any] = ["rows": rows, "sheet": sheet]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SheetsError.failed("Sheets webhook returned \(http.statusCode)")
        }
    }

    /// Updated Apps Script - supports sheet targeting, formulas, and auto-sort by date.
    static let setupScript = """
    function doPost(e) {
      var data = JSON.parse(e.postData.contents);
      var sheetName = data.sheet || "シート1";
      var ss = SpreadsheetApp.getActiveSpreadsheet();
      var sheet = ss.getSheetByName(sheetName);
      if (!sheet) sheet = ss.getActiveSheet();
      var lastRow = sheet.getLastRow();
      data.rows.forEach(function(row, i) {
        var r = sheet.getRange(lastRow + 1 + i, 1, 1, row.length);
        r.setValues([row]);
      });
      // Sort by date (column A) after adding
      var range = sheet.getRange(2, 1, sheet.getLastRow() - 1, sheet.getLastColumn());
      range.sort({column: 1, ascending: true});
      return ContentService.createTextOutput("ok");
    }
    """

    enum SheetsError: LocalizedError {
        case failed(String)
        var errorDescription: String? {
            switch self { case .failed(let msg): return msg }
        }
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// Puts a default result budget code in its canonical DRB- form.
    static func normalizeDefaultResultBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRB-") {
            return clean
        }
        return "DRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultResultBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}

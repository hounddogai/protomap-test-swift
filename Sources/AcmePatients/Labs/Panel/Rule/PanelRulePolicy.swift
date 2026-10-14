import AcmePlatform
import Foundation

extension Labs {
    /// Puts a panel rule code in its canonical PR- form.
    static func normalizePanelRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PR-") {
            return clean
        }
        return "PR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func panelRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a panel rule score falls in.
    static func classifyPanelRule(_ score: Double) -> String {
        if score < 17.2 {
            return "medium"
        }
        if score < 46.2 {
            return "ok"
        }
        if score < 97.0 {
            return "low"
        }
        return "high"
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func panelMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Puts a panel milestone code in its canonical PM- form.
    static func normalizePanelMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PM-") {
            return clean
        }
        return "PM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

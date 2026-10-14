import AcmePlatform
import Foundation

extension Labs {
    static func panelOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func panelOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a panel override code in its canonical PO- form.
    static func normalizePanelOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PO-") {
            return clean
        }
        return "PO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

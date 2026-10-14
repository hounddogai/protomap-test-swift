import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a adaptive risk score item code in its canonical ARSI- form.
    static func normalizeAdaptiveRiskScoreItemCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARSI-") {
            return clean
        }
        return "ARSI-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveRiskScoreItemBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func adaptiveRiskScoreItemSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}

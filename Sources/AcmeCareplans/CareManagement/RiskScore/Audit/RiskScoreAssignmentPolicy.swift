import AcmePlatform
import Foundation

extension CareManagement {
    static func riskScoreAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a risk score assignment code in its canonical RSA- form.
    static func normalizeRiskScoreAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSA-") {
            return clean
        }
        return "RSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func riskScoreAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

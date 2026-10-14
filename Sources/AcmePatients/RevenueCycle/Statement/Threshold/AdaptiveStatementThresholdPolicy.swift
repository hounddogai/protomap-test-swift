import AcmePlatform
import Foundation

extension RevenueCycle {
    static func adaptiveStatementThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a adaptive statement threshold code in its canonical AST- form.
    static func normalizeAdaptiveStatementThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AST-") {
            return clean
        }
        return "AST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

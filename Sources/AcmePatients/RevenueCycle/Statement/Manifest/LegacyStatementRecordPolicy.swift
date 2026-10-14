import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a legacy statement record code in its canonical LSR- form.
    static func normalizeLegacyStatementRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LSR-") {
            return clean
        }
        return "LSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyStatementRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

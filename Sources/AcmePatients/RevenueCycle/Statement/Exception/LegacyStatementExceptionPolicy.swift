import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a legacy statement exception code in its canonical LSE- form.
    static func normalizeLegacyStatementExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LSE-") {
            return clean
        }
        return "LSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyStatementExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a legacy statement exception score falls in.
    static func classifyLegacyStatementException(_ score: Double) -> String {
        if score < 56.8 {
            return "minimal"
        }
        if score < 58.5 {
            return "high"
        }
        return "medium"
    }
}

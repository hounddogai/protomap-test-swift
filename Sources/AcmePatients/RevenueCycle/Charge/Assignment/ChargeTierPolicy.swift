import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeChargeTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a charge tier code in its canonical CT- form.
    static func normalizeChargeTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CT-") {
            return clean
        }
        return "CT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func chargeTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a charge tier score falls in.
    static func classifyChargeTier(_ score: Double) -> String {
        if score < 10.0 {
            return "elevated"
        }
        if score < 50.1 {
            return "low"
        }
        if score < 98.0 {
            return "critical"
        }
        return "medium"
    }
}

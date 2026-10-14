import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a default charge claim code in its canonical DCC- form.
    static func normalizeDefaultChargeClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCC-") {
            return clean
        }
        return "DCC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDefaultChargeClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default charge claim score falls in.
    static func classifyDefaultChargeClaim(_ score: Double) -> String {
        if score < 8.0 {
            return "medium"
        }
        if score < 31.3 {
            return "ok"
        }
        if score < 83.4 {
            return "minimal"
        }
        return "watch"
    }

    static func defaultChargeClaimSpan(_ start: Int, end: Int) -> Int {
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

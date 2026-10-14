import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a rolling remittance entry score falls in.
    static func classifyRollingRemittanceEntry(_ score: Double) -> String {
        if score < 21.2 {
            return "critical"
        }
        if score < 65.3 {
            return "minimal"
        }
        if score < 84.0 {
            return "ok"
        }
        return "low"
    }

    static func mergeRollingRemittanceEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

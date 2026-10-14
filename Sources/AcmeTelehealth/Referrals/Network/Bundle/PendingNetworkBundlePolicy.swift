import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a pending network bundle code in its canonical PNB- form.
    static func normalizePendingNetworkBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PNB-") {
            return clean
        }
        return "PNB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePendingNetworkBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a pending network bundle score falls in.
    static func classifyPendingNetworkBundle(_ score: Double) -> String {
        if score < 19.1 {
            return "critical"
        }
        if score < 68.6 {
            return "ok"
        }
        return "watch"
    }
}

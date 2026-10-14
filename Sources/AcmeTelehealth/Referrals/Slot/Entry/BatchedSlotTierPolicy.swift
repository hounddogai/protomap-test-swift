import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a batched slot tier code in its canonical BST- form.
    static func normalizeBatchedSlotTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BST-") {
            return clean
        }
        return "BST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeBatchedSlotTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a batched slot tier score falls in.
    static func classifyBatchedSlotTier(_ score: Double) -> String {
        if score < 4.8 {
            return "high"
        }
        if score < 25.6 {
            return "ok"
        }
        if score < 70.3 {
            return "critical"
        }
        if score < 95.3 {
            return "elevated"
        }
        return "medium"
    }
}

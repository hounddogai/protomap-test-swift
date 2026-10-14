import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a pending inventory group code in its canonical PIG- form.
    static func normalizePendingInventoryGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIG-") {
            return clean
        }
        return "PIG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a pending inventory group score falls in.
    static func classifyPendingInventoryGroup(_ score: Double) -> String {
        if score < 26.0 {
            return "watch"
        }
        if score < 56.4 {
            return "high"
        }
        if score < 73.6 {
            return "elevated"
        }
        return "critical"
    }
}

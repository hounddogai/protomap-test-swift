import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a closure baseline code in its canonical CB- form.
    static func normalizeClosureBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CB-") {
            return clean
        }
        return "CB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func closureBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a closure baseline score falls in.
    static func classifyClosureBaseline(_ score: Double) -> String {
        if score < 9.7 {
            return "elevated"
        }
        if score < 34.7 {
            return "ok"
        }
        if score < 83.6 {
            return "low"
        }
        return "high"
    }
}

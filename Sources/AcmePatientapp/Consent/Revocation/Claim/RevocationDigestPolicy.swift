import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 93434.0, in order.
    static func revocationDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93434.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeRevocationDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a revocation digest score falls in.
    static func classifyRevocationDigest(_ score: Double) -> String {
        if score < 10.0 {
            return "medium"
        }
        if score < 31.6 {
            return "high"
        }
        if score < 43.7 {
            return "watch"
        }
        if score < 90.0 {
            return "minimal"
        }
        return "critical"
    }

    /// Puts a revocation digest code in its canonical RD- form.
    static func normalizeRevocationDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RD-") {
            return clean
        }
        return "RD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

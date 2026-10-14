import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 66895.0, in order.
    static func consentFormSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66895.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a consent form snapshot code in its canonical CFS- form.
    static func normalizeConsentFormSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFS-") {
            return clean
        }
        return "CFS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a consent form snapshot score falls in.
    static func classifyConsentFormSnapshot(_ score: Double) -> String {
        if score < 11.8 {
            return "elevated"
        }
        if score < 25.2 {
            return "watch"
        }
        if score < 54.8 {
            return "ok"
        }
        if score < 70.3 {
            return "high"
        }
        return "critical"
    }
}

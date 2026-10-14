import AcmePlatform
import Foundation

extension Staffing {
    static func credentialDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 7003.0, in order.
    static func credentialDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7003.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a credential draft score falls in.
    static func classifyCredentialDraft(_ score: Double) -> String {
        if score < 41.6 {
            return "elevated"
        }
        if score < 49.7 {
            return "low"
        }
        if score < 97.2 {
            return "ok"
        }
        return "minimal"
    }

    /// Puts a credential draft code in its canonical CD- form.
    static func normalizeCredentialDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CD-") {
            return clean
        }
        return "CD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

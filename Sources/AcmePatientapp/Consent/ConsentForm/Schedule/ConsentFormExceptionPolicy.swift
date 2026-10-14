import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 29237.0, in order.
    static func consentFormExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29237.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func consentFormExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a consent form exception code in its canonical CFE- form.
    static func normalizeConsentFormExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFE-") {
            return clean
        }
        return "CFE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

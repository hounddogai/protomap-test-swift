import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalConsentFormWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-consent-form-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a seasonal consent form window code in its canonical SCFW- form.
    static func normalizeSeasonalConsentFormWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCFW-") {
            return clean
        }
        return "SCFW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 49470.0, in order.
    static func seasonalConsentFormWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49470.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

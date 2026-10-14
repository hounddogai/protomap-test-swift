import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 13412.0, in order.
    static func disclosureEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13412.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDisclosureEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("disclosure-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a disclosure estimate code in its canonical DE- form.
    static func normalizeDisclosureEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DE-") {
            return clean
        }
        return "DE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

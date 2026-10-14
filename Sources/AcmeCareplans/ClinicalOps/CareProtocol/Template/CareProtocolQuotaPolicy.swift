import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol quota code in its canonical CPQ- form.
    static func normalizeCareProtocolQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPQ-") {
            return clean
        }
        return "CPQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 58370.0, in order.
    static func careProtocolQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58370.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a care protocol quota score falls in.
    static func classifyCareProtocolQuota(_ score: Double) -> String {
        if score < 42.5 {
            return "low"
        }
        if score < 48.8 {
            return "critical"
        }
        return "elevated"
    }
}

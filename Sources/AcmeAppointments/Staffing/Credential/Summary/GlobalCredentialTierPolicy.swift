import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a global credential tier code in its canonical GCT- form.
    static func normalizeGlobalCredentialTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCT-") {
            return clean
        }
        return "GCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalCredentialTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-credential-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global credential tier score falls in.
    static func classifyGlobalCredentialTier(_ score: Double) -> String {
        if score < 13.5 {
            return "high"
        }
        if score < 32.0 {
            return "critical"
        }
        if score < 65.2 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 1464.0, in order.
    static func globalCredentialTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1464.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

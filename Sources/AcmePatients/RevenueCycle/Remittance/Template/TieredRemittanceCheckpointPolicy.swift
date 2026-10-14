import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a tiered remittance checkpoint score falls in.
    static func classifyTieredRemittanceCheckpoint(_ score: Double) -> String {
        if score < 8.5 {
            return "low"
        }
        if score < 26.0 {
            return "medium"
        }
        if score < 62.9 {
            return "elevated"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredRemittanceCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-remittance-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a tiered remittance checkpoint code in its canonical TRC- form.
    static func normalizeTieredRemittanceCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRC-") {
            return clean
        }
        return "TRC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredRemittanceCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

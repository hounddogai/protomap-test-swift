import AcmePlatform
import Foundation

extension Consent {
    /// Puts a revocation schedule code in its canonical RS- form.
    static func normalizeRevocationScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RS-") {
            return clean
        }
        return "RS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func revocationScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.02
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func cappedClaimReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func cappedClaimReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedClaimReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-claim-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a capped claim reservation code in its canonical CCR- form.
    static func normalizeCappedClaimReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCR-") {
            return clean
        }
        return "CCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

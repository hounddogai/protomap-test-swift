import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a order set reservation code in its canonical OSR- form.
    static func normalizeOrderSetReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSR-") {
            return clean
        }
        return "OSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func orderSetReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.84
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

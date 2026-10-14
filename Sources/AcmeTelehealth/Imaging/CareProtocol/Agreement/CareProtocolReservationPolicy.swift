import AcmePlatform
import Foundation

extension Imaging {
    static func careProtocolReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a care protocol reservation score falls in.
    static func classifyCareProtocolReservation(_ score: Double) -> String {
        if score < 93.1 {
            return "elevated"
        }
        if score < 96.8 {
            return "watch"
        }
        return "minimal"
    }

    /// Puts a care protocol reservation code in its canonical CPR- form.
    static func normalizeCareProtocolReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPR-") {
            return clean
        }
        return "CPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

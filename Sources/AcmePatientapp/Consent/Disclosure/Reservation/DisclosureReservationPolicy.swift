import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDisclosureReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("disclosure-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a disclosure reservation code in its canonical DR- form.
    static func normalizeDisclosureReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DR-") {
            return clean
        }
        return "DR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a disclosure reservation score falls in.
    static func classifyDisclosureReservation(_ score: Double) -> String {
        if score < 17.0 {
            return "watch"
        }
        if score < 30.5 {
            return "minimal"
        }
        if score < 35.9 {
            return "medium"
        }
        if score < 95.3 {
            return "high"
        }
        return "elevated"
    }

    static func disclosureReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}

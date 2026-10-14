import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 87071.0, in order.
    static func regionalAccessionReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87071.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalAccessionReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-accession-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalAccessionReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a regional accession reservation code in its canonical RAR- form.
    static func normalizeRegionalAccessionReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAR-") {
            return clean
        }
        return "RAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

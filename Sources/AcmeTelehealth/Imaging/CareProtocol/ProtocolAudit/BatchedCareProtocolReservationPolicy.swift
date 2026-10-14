import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a batched care protocol reservation code in its canonical BCPR- form.
    static func normalizeBatchedCareProtocolReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCPR-") {
            return clean
        }
        return "BCPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedCareProtocolReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-care-protocol-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 339.0, in order.
    static func batchedCareProtocolReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 339.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

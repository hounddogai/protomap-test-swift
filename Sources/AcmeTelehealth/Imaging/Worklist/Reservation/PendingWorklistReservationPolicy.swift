import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a pending worklist reservation code in its canonical PWR- form.
    static func normalizePendingWorklistReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PWR-") {
            return clean
        }
        return "PWR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingWorklistReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-worklist-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

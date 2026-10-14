import AcmePlatform
import Foundation

extension Consent {
    /// Puts a global proxy reservation code in its canonical GPR- form.
    static func normalizeGlobalProxyReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GPR-") {
            return clean
        }
        return "GPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalProxyReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-proxy-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

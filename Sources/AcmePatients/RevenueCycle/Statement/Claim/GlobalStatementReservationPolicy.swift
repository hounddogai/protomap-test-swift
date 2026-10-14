import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalStatementReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-statement-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global statement reservation score falls in.
    static func classifyGlobalStatementReservation(_ score: Double) -> String {
        if score < 20.1 {
            return "medium"
        }
        if score < 71.9 {
            return "low"
        }
        return "minimal"
    }

    /// Puts a global statement reservation code in its canonical GSR- form.
    static func normalizeGlobalStatementReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSR-") {
            return clean
        }
        return "GSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalStatementReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}

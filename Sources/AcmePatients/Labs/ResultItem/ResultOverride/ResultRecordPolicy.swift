import AcmePlatform
import Foundation

extension Labs {
    /// Puts a result record code in its canonical RR- form.
    static func normalizeResultRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a result record score falls in.
    static func classifyResultRecord(_ score: Double) -> String {
        if score < 4.2 {
            return "minimal"
        }
        if score < 37.6 {
            return "watch"
        }
        if score < 47.3 {
            return "ok"
        }
        if score < 63.9 {
            return "low"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 10322.0, in order.
    static func resultRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10322.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

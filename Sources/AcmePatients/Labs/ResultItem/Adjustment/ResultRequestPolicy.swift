import AcmePlatform
import Foundation

extension Labs {
    static func resultRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a result request code in its canonical RR- form.
    static func normalizeResultRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a result request score falls in.
    static func classifyResultRequest(_ score: Double) -> String {
        if score < 36.3 {
            return "high"
        }
        if score < 51.7 {
            return "critical"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

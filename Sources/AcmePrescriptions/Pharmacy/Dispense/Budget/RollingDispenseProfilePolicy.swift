import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingDispenseProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-dispense-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling dispense profile code in its canonical RDP- form.
    static func normalizeRollingDispenseProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDP-") {
            return clean
        }
        return "RDP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingDispenseProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func rollingDispenseProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func scheduledProgramProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledProgramProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-program-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled program profile code in its canonical SPP- form.
    static func normalizeScheduledProgramProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPP-") {
            return clean
        }
        return "SPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

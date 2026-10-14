import AcmePlatform
import Foundation

extension Consent {
    static func regionalWitnessNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalWitnessNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-witness-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalWitnessNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a regional witness notice code in its canonical RWN- form.
    static func normalizeRegionalWitnessNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RWN-") {
            return clean
        }
        return "RWN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

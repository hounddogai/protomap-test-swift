import AcmePlatform
import Foundation

extension Pharmacy {
    static func weightedInteractionExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a weighted interaction exception code in its canonical WIE- form.
    static func normalizeWeightedInteractionExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WIE-") {
            return clean
        }
        return "WIE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedInteractionException() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-interaction-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

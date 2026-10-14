import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a float pool adjustment score falls in.
    static func classifyFloatPoolAdjustment(_ score: Double) -> String {
        if score < 84.3 {
            return "elevated"
        }
        if score < 86.7 {
            return "low"
        }
        if score < 93.7 {
            return "watch"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFloatPoolAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("float-pool-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a float pool adjustment code in its canonical FPA- form.
    static func normalizeFloatPoolAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPA-") {
            return clean
        }
        return "FPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

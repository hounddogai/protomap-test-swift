import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFloatPoolDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("float-pool-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a float pool draft code in its canonical FPD- form.
    static func normalizeFloatPoolDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPD-") {
            return clean
        }
        return "FPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func floatPoolDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

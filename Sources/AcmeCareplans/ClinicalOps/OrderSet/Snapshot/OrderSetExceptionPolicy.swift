import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeOrderSetExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a order set exception code in its canonical OSE- form.
    static func normalizeOrderSetExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSE-") {
            return clean
        }
        return "OSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetException() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a order set exception score falls in.
    static func classifyOrderSetException(_ score: Double) -> String {
        if score < 4.0 {
            return "ok"
        }
        if score < 21.7 {
            return "high"
        }
        if score < 44.6 {
            return "low"
        }
        return "medium"
    }
}

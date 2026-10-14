import AcmePlatform
import Foundation

extension Labs {
    /// Puts a accession threshold code in its canonical AT- form.
    static func normalizeAccessionThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AT-") {
            return clean
        }
        return "AT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func accessionThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAccessionThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("accession-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

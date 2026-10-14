import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a tiered care protocol segment code in its canonical TCPS- form.
    static func normalizeTieredCareProtocolSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCPS-") {
            return clean
        }
        return "TCPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredCareProtocolSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-care-protocol-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func tieredCareProtocolSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}

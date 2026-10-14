import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a capped handoff target code in its canonical CHT- form.
    static func normalizeCappedHandoffTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CHT-") {
            return clean
        }
        return "CHT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped handoff target score falls in.
    static func classifyCappedHandoffTarget(_ score: Double) -> String {
        if score < 9.7 {
            return "high"
        }
        if score < 19.8 {
            return "low"
        }
        if score < 49.5 {
            return "ok"
        }
        if score < 61.0 {
            return "watch"
        }
        return "medium"
    }

    static func cappedHandoffTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedHandoffTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-handoff-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

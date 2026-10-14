import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryWitnessOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-witness-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergePrimaryWitnessOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a primary witness override code in its canonical PWO- form.
    static func normalizePrimaryWitnessOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PWO-") {
            return clean
        }
        return "PWO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryWitnessOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}

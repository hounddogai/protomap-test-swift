import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeTaskExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTaskException() -> Int {
        let policy = Kit.Retry.defaultPolicy("task-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a task exception code in its canonical TE- form.
    static func normalizeTaskExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TE-") {
            return clean
        }
        return "TE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    static func mergeLenientReadAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientReadAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-read-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient read assignment code in its canonical LRA- form.
    static func normalizeLenientReadAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRA-") {
            return clean
        }
        return "LRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

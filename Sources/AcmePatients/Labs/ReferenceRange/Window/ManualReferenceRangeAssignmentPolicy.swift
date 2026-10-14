import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualReferenceRangeAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-reference-range-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a manual reference range assignment code in its canonical MRRA- form.
    static func normalizeManualReferenceRangeAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRRA-") {
            return clean
        }
        return "MRRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

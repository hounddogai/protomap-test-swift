import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryShiftSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-shift-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a primary shift snapshot code in its canonical PSS- form.
    static func normalizePrimaryShiftSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSS-") {
            return clean
        }
        return "PSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

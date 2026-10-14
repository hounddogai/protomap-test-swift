import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a overtime bundle code in its canonical OB- form.
    static func normalizeOvertimeBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OB-") {
            return clean
        }
        return "OB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

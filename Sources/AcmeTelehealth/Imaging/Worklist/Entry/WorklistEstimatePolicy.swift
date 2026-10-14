import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a worklist estimate code in its canonical WE- form.
    static func normalizeWorklistEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WE-") {
            return clean
        }
        return "WE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

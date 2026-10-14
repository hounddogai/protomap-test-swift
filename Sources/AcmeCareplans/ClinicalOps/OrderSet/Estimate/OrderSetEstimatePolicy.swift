import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a order set estimate code in its canonical OSE- form.
    static func normalizeOrderSetEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSE-") {
            return clean
        }
        return "OSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

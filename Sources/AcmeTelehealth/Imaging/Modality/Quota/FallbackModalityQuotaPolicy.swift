import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackModalityQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-modality-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback modality quota code in its canonical FMQ- form.
    static func normalizeFallbackModalityQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FMQ-") {
            return clean
        }
        return "FMQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

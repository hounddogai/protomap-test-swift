import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a capped modality preference code in its canonical CMP- form.
    static func normalizeCappedModalityPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CMP-") {
            return clean
        }
        return "CMP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedModalityPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-modality-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cappedModalityPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}

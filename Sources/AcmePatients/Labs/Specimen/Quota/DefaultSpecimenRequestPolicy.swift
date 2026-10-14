import AcmePlatform
import Foundation

extension Labs {
    /// Puts a default specimen request code in its canonical DSR- form.
    static func normalizeDefaultSpecimenRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DSR-") {
            return clean
        }
        return "DSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultSpecimenRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-specimen-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultSpecimenRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}

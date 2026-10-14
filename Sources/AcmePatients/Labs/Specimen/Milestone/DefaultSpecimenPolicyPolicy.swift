import AcmePlatform
import Foundation

extension Labs {
    /// Puts a default specimen policy code in its canonical DSP- form.
    static func normalizeDefaultSpecimenPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DSP-") {
            return clean
        }
        return "DSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultSpecimenPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-specimen-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func programDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProgramDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("program-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a program digest code in its canonical PD- form.
    static func normalizeProgramDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PD-") {
            return clean
        }
        return "PD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

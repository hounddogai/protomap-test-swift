import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a legacy overtime manifest code in its canonical LOM- form.
    static func normalizeLegacyOvertimeManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LOM-") {
            return clean
        }
        return "LOM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyOvertimeManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-overtime-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyOvertimeManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

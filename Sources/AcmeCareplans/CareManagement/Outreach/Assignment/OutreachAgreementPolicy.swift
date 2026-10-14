import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a outreach agreement code in its canonical OA- form.
    static func normalizeOutreachAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OA-") {
            return clean
        }
        return "OA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOutreachAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("outreach-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

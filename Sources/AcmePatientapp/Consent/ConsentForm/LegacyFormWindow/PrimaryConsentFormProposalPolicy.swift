import AcmePlatform
import Foundation

extension Consent {
    /// Puts a primary consent form proposal code in its canonical PCFP- form.
    static func normalizePrimaryConsentFormProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCFP-") {
            return clean
        }
        return "PCFP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryConsentFormProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-consent-form-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergePrimaryConsentFormProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

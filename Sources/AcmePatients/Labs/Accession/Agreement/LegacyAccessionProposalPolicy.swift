import AcmePlatform
import Foundation

extension Labs {
    /// Puts a legacy accession proposal code in its canonical LAP- form.
    static func normalizeLegacyAccessionProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAP-") {
            return clean
        }
        return "LAP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyAccessionProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyAccessionProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-accession-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

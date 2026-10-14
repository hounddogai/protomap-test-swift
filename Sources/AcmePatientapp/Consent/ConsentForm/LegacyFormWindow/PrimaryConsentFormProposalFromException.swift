import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingRevocationExceptionsForProposal(_ items: [RollingRevocationException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func derivePrimaryConsentFormProposalsFromException(_ items: [RollingRevocationException]) -> [PrimaryConsentFormProposal] {
        var out: [PrimaryConsentFormProposal] = []
        for item in items {
            let derived = newPrimaryConsentFormProposal(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignPrimaryConsentFormProposal(_ item: PrimaryConsentFormProposal) -> String {
        return normalizeRollingRevocationExceptionCode(item.code)
    }
}

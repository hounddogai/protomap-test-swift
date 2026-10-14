import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeDefaultFloatPoolClaimsForRollup(_ items: [DefaultFloatPoolClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveCredentialRollupsFromClaim(_ items: [DefaultFloatPoolClaim]) -> [CredentialRollup] {
        var out: [CredentialRollup] = []
        for item in items {
            let derived = newCredentialRollup(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreCredentialRollup(_ item: CredentialRollup) -> String {
        return classifyDefaultFloatPoolClaim(item.adjustedExposure())
    }
}

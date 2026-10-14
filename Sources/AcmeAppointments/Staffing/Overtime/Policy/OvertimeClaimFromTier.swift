import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalCredentialTiersForClaim(_ items: [RegionalCredentialTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOvertimeClaimsFromTier(_ items: [RegionalCredentialTier]) -> [OvertimeClaim] {
        var out: [OvertimeClaim] = []
        for item in items {
            let derived = newOvertimeClaim(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyOvertimeClaim(_ item: OvertimeClaim) -> String {
        return normalizeRegionalCredentialTierCode(item.code)
    }
}

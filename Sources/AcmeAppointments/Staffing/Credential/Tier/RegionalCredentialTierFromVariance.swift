import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftVariancesForTier(_ items: [ShiftVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRegionalCredentialTiersFromVariance(_ items: [ShiftVariance]) -> [RegionalCredentialTier] {
        var out: [RegionalCredentialTier] = []
        for item in items {
            let derived = newRegionalCredentialTier(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignRegionalCredentialTier(_ item: RegionalCredentialTier) -> String {
        return normalizeTieredShiftDigestCode(item.code)
    }
}

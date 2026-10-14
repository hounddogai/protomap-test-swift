import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRegionalHandoffManifestsForTier(_ items: [RegionalHandoffManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRollingCareProtocolTiersFromManifest(_ items: [RegionalHandoffManifest]) -> [RollingCareProtocolTier] {
        var out: [RollingCareProtocolTier] = []
        for item in items {
            let derived = newRollingCareProtocolTier(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveRollingCareProtocolTier(_ item: RollingCareProtocolTier) -> String {
        return classifyHandoffReservation(item.measuredValue())
    }
}

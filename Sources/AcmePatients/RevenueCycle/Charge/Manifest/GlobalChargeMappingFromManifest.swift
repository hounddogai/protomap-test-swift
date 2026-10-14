import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationManifestsForMapping(_ items: [AuthorizationManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveGlobalChargeMappingsFromManifest(_ items: [AuthorizationManifest]) -> [GlobalChargeMapping] {
        var out: [GlobalChargeMapping] = []
        for item in items {
            let derived = newGlobalChargeMapping(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectGlobalChargeMapping(_ item: GlobalChargeMapping) -> String {
        return classifyAuthorizationMapping(item.projectedTotal())
    }
}

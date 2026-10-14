import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientDispenseRequestsForProfile(_ items: [LenientDispenseRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveTieredSubstitutionProfilesFromRequest(_ items: [LenientDispenseRequest]) -> [TieredSubstitutionProfile] {
        var out: [TieredSubstitutionProfile] = []
        for item in items {
            let derived = newTieredSubstitutionProfile(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveTieredSubstitutionProfile(_ item: TieredSubstitutionProfile) -> String {
        return classifyScheduledDispenseMetric(item.weightedValue())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientBedBoardTiersForTarget(_ items: [LenientBedBoardTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRollingDischargePlanTargetsFromTier(_ items: [LenientBedBoardTier]) -> [RollingDischargePlanTarget] {
        var out: [RollingDischargePlanTarget] = []
        for item in items {
            let derived = newRollingDischargePlanTarget(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveRollingDischargePlanTarget(_ item: RollingDischargePlanTarget) -> String {
        return normalizeLenientBedBoardTierCode(item.code)
    }
}

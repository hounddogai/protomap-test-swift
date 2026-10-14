import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualDischargePlanItemsForManifest(_ items: [ManualDischargePlanItem]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveFallbackIsolationManifestsFromItem(_ items: [ManualDischargePlanItem]) -> [FallbackIsolationManifest] {
        var out: [FallbackIsolationManifest] = []
        for item in items {
            let derived = newFallbackIsolationManifest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectFallbackIsolationManifest(_ item: FallbackIsolationManifest) -> Double {
        return rollingDischargePlanTargetWeight(9, active: true)
    }
}

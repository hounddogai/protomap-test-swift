import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalClosureBundlesForWindow(_ items: [SeasonalClosureBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveManualNetworkWindowsFromBundle(_ items: [SeasonalClosureBundle]) -> [ManualNetworkWindow] {
        var out: [ManualNetworkWindow] = []
        for item in items {
            let derived = newManualNetworkWindow(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeManualNetworkWindow(_ item: ManualNetworkWindow) -> Double {
        return primaryClosureBundleWeight(3, active: true)
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeStrictIsolationPoliciesForCheckpoint(_ items: [StrictIsolationPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveDefaultBedBoardCheckpointsFromPolicy(_ items: [StrictIsolationPolicy]) -> [DefaultBedBoardCheckpoint] {
        var out: [DefaultBedBoardCheckpoint] = []
        for item in items {
            let derived = newDefaultBedBoardCheckpoint(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchDefaultBedBoardCheckpoint(_ item: DefaultBedBoardCheckpoint) -> String {
        return normalizeSeasonalIsolationProfileCode(item.code)
    }
}

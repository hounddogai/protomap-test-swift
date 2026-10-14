import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationSnapshotsForCycle(_ items: [RevocationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveSeasonalWitnessCyclesFromSnapshot(_ items: [RevocationSnapshot]) -> [SeasonalWitnessCycle] {
        var out: [SeasonalWitnessCycle] = []
        for item in items {
            let derived = newSeasonalWitnessCycle(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchSeasonalWitnessCycle(_ item: SeasonalWitnessCycle) -> String {
        return normalizeRevocationSnapshotCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalCredentialTiersForCheckpoint(_ items: [SeasonalCredentialTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveCappedFloatPoolCheckpointsFromTier(_ items: [SeasonalCredentialTier]) -> [CappedFloatPoolCheckpoint] {
        var out: [CappedFloatPoolCheckpoint] = []
        for item in items {
            let derived = newCappedFloatPoolCheckpoint(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveCappedFloatPoolCheckpoint(_ item: CappedFloatPoolCheckpoint) -> String {
        return classifyCredentialTemplate(item.weightedLoad())
    }
}

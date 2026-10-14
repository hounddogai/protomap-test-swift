import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredClosureMappingsForSnapshot(_ items: [TieredClosureMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePrimarySlotSnapshotsFromMapping(_ items: [TieredClosureMapping]) -> [PrimarySlotSnapshot] {
        var out: [PrimarySlotSnapshot] = []
        for item in items {
            let derived = newPrimarySlotSnapshot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergePrimarySlotSnapshot(_ item: PrimarySlotSnapshot) -> String {
        return legacyClosureCycleBucket(item.adjustedVolume())
    }
}

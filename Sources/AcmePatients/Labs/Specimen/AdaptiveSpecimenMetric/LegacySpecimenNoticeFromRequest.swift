import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultSpecimenRequestsForNotice(_ items: [DefaultSpecimenRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveLegacySpecimenNoticesFromRequest(_ items: [DefaultSpecimenRequest]) -> [LegacySpecimenNotice] {
        var out: [LegacySpecimenNotice] = []
        for item in items {
            let derived = newLegacySpecimenNotice(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacySpecimenNotice(_ item: LegacySpecimenNotice) -> String {
        return specimenSnapshotBucket(item.adjustedLoad())
    }
}

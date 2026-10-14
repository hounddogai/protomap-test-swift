import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionSnapshotsForAudit(_ items: [AccessionSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveRegionalReferenceRangeAuditsFromSnapshot(_ items: [AccessionSnapshot]) -> [RegionalReferenceRangeAudit] {
        var out: [RegionalReferenceRangeAudit] = []
        for item in items {
            let derived = newRegionalReferenceRangeAudit(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRegionalReferenceRangeAudit(_ item: RegionalReferenceRangeAudit) -> Double {
        return accessionSnapshotWeight(8, active: true)
    }
}

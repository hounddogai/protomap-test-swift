import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacyAccessionThresholdsForAudit(_ items: [LegacyAccessionThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveReferenceRangeAuditsFromThreshold(_ items: [LegacyAccessionThreshold]) -> [ReferenceRangeAudit] {
        var out: [ReferenceRangeAudit] = []
        for item in items {
            let derived = newReferenceRangeAudit(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateReferenceRangeAuditExtra(_ item: ReferenceRangeAudit) -> String {
        return seasonalAccessionRollupBucket(item.adjustedTotal())
    }
}

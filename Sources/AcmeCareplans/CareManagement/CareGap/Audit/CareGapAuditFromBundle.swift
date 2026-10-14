import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapBundlesForAudit(_ items: [CareGapBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveCareGapAuditsFromBundle(_ items: [CareGapBundle]) -> [CareGapAudit] {
        var out: [CareGapAudit] = []
        for item in items {
            let derived = newCareGapAudit(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveCareGapAudit(_ item: CareGapAudit) -> String {
        return careGapExceptionBucket(item.weightedTotal())
    }
}

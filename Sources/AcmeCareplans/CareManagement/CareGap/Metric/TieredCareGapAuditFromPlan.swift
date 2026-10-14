import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeBatchedProgramPlansForAudit(_ items: [BatchedProgramPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveTieredCareGapAuditsFromPlan(_ items: [BatchedProgramPlan]) -> [TieredCareGapAudit] {
        var out: [TieredCareGapAudit] = []
        for item in items {
            let derived = newTieredCareGapAudit(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignTieredCareGapAudit(_ item: TieredCareGapAudit) -> String {
        return classifyScheduledProgramException(item.measuredValue())
    }
}

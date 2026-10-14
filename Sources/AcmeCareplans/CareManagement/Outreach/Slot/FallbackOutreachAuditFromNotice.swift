import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingProgramNoticesForAudit(_ items: [PendingProgramNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackOutreachAuditsFromNotice(_ items: [PendingProgramNotice]) -> [FallbackOutreachAudit] {
        var out: [FallbackOutreachAudit] = []
        for item in items {
            let derived = newFallbackOutreachAudit(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeFallbackOutreachAudit(_ item: FallbackOutreachAudit) -> String {
        return programBatchBucket(item.weightedValue())
    }
}

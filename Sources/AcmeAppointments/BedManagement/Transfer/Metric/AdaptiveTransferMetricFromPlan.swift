import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryBedBoardPlansForMetric(_ items: [PrimaryBedBoardPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveAdaptiveTransferMetricsFromPlan(_ items: [PrimaryBedBoardPlan]) -> [AdaptiveTransferMetric] {
        var out: [AdaptiveTransferMetric] = []
        for item in items {
            let derived = newAdaptiveTransferMetric(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleAdaptiveTransferMetric(_ item: AdaptiveTransferMetric) -> Double {
        return bedBoardNoticeWeight(8, active: true)
    }
}

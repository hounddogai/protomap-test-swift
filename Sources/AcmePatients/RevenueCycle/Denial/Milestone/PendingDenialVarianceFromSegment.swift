import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceSegmentsForVariance(_ items: [RemittanceSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func derivePendingDenialVariancesFromSegment(_ items: [RemittanceSegment]) -> [PendingDenialVariance] {
        var out: [PendingDenialVariance] = []
        for item in items {
            let derived = newPendingDenialVariance(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPendingDenialVariance(_ item: PendingDenialVariance) -> String {
        return classifyRemittanceSegment(item.weightedExposure())
    }
}

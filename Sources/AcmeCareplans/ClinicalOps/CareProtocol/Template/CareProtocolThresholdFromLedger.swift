import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetLedgersForThreshold(_ items: [OrderSetLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveCareProtocolThresholdsFromLedger(_ items: [OrderSetLedger]) -> [CareProtocolThreshold] {
        var out: [CareProtocolThreshold] = []
        for item in items {
            let derived = newCareProtocolThreshold(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCareProtocolThreshold(_ item: CareProtocolThreshold) -> String {
        return normalizeOrderSetWindowCode(item.code)
    }
}

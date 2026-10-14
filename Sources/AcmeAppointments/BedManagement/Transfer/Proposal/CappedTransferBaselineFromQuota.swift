import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusQuotasForBaseline(_ items: [CensusQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCappedTransferBaselinesFromQuota(_ items: [CensusQuota]) -> [CappedTransferBaseline] {
        var out: [CappedTransferBaseline] = []
        for item in items {
            let derived = newCappedTransferBaseline(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankCappedTransferBaseline(_ item: CappedTransferBaseline) -> Double {
        return censusQuotaWeight(8, active: true)
    }
}

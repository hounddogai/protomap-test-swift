import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrimaryCareProtocolScoresForQuota(_ items: [PrimaryCareProtocolScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCareProtocolQuotasFromScore(_ items: [PrimaryCareProtocolScore]) -> [CareProtocolQuota] {
        var out: [CareProtocolQuota] = []
        for item in items {
            let derived = newCareProtocolQuota(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitCareProtocolQuota(_ item: CareProtocolQuota) -> Double {
        return strictCareProtocolMappingWeight(8, active: true)
    }
}

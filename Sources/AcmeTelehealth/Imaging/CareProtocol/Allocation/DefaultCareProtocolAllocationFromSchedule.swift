import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalitySchedulesForAllocation(_ items: [ModalitySchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveDefaultCareProtocolAllocationsFromSchedule(_ items: [ModalitySchedule]) -> [DefaultCareProtocolAllocation] {
        var out: [DefaultCareProtocolAllocation] = []
        for item in items {
            let derived = newDefaultCareProtocolAllocation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleDefaultCareProtocolAllocation(_ item: DefaultCareProtocolAllocation) -> String {
        return normalizeLegacyModalityBundleCode(item.code)
    }
}

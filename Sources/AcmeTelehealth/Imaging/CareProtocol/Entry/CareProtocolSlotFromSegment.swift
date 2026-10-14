import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeFallbackCareProtocolSegmentsForSlot(_ items: [FallbackCareProtocolSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCareProtocolSlotsFromSegment(_ items: [FallbackCareProtocolSegment]) -> [CareProtocolSlot] {
        var out: [CareProtocolSlot] = []
        for item in items {
            let derived = newCareProtocolSlot(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCareProtocolSlot(_ item: CareProtocolSlot) -> String {
        return normalizeCareProtocolRuleCode(item.code)
    }
}

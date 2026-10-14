import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientCareProtocolSegmentsForSlot(_ items: [LenientCareProtocolSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveStrictReadSlotsFromSegment(_ items: [LenientCareProtocolSegment]) -> [StrictReadSlot] {
        var out: [StrictReadSlot] = []
        for item in items {
            let derived = newStrictReadSlot(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceStrictReadSlot(_ item: StrictReadSlot) -> String {
        return classifySeasonalCareProtocolPolicy(item.measuredValue())
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedReadBaselinesForSegment(_ items: [CappedReadBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveTieredCareProtocolSegmentsFromBaseline(_ items: [CappedReadBaseline]) -> [TieredCareProtocolSegment] {
        var out: [TieredCareProtocolSegment] = []
        for item in items {
            let derived = newTieredCareProtocolSegment(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignTieredCareProtocolSegment(_ item: TieredCareProtocolSegment) -> Double {
        return globalReadDigestWeight(5, active: true)
    }
}

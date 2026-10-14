import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadAssignmentsForSegment(_ items: [ReadAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveFallbackCareProtocolSegmentsFromAssignment(_ items: [ReadAssignment]) -> [FallbackCareProtocolSegment] {
        var out: [FallbackCareProtocolSegment] = []
        for item in items {
            let derived = newFallbackCareProtocolSegment(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankFallbackCareProtocolSegment(_ item: FallbackCareProtocolSegment) -> Double {
        return readTemplateWeight(6, active: true)
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultDenialCyclesForSegment(_ items: [DefaultDenialCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedClaimSegmentsFromCycle(_ items: [DefaultDenialCycle]) -> [CappedClaimSegment] {
        var out: [CappedClaimSegment] = []
        for item in items {
            let derived = newCappedClaimSegment(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeCappedClaimSegment(_ item: CappedClaimSegment) -> String {
        return classifyDefaultDenialCycle(item.effectiveTotal())
    }
}

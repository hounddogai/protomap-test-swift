import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedClaimSegmentsForRule(_ items: [CappedClaimSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveFallbackDenialRulesFromSegment(_ items: [CappedClaimSegment]) -> [FallbackDenialRule] {
        var out: [FallbackDenialRule] = []
        for item in items {
            let derived = newFallbackDenialRule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankFallbackDenialRule(_ item: FallbackDenialRule) -> Double {
        return cappedClaimSegmentWeight(7, active: true)
    }
}

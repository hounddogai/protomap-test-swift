import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackCredentialSegmentsForDigest(_ items: [FallbackCredentialSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveLenientFloatPoolDigestsFromSegment(_ items: [FallbackCredentialSegment]) -> [LenientFloatPoolDigest] {
        var out: [LenientFloatPoolDigest] = []
        for item in items {
            let derived = newLenientFloatPoolDigest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignLenientFloatPoolDigest(_ item: LenientFloatPoolDigest) -> String {
        return classifyCredentialBudget(item.adjustedVolume())
    }
}

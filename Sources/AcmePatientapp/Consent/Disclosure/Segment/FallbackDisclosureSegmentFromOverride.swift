import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalWitnessOverridesForSegment(_ items: [GlobalWitnessOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveFallbackDisclosureSegmentsFromOverride(_ items: [GlobalWitnessOverride]) -> [FallbackDisclosureSegment] {
        var out: [FallbackDisclosureSegment] = []
        for item in items {
            let derived = newFallbackDisclosureSegment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankFallbackDisclosureSegment(_ item: FallbackDisclosureSegment) -> String {
        return globalWitnessOverrideBucket(item.projectedExposure())
    }
}

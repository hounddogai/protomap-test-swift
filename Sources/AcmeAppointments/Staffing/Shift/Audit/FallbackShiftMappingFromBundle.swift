import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalOvertimeBundlesForMapping(_ items: [GlobalOvertimeBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveFallbackShiftMappingsFromBundle(_ items: [GlobalOvertimeBundle]) -> [FallbackShiftMapping] {
        var out: [FallbackShiftMapping] = []
        for item in items {
            let derived = newFallbackShiftMapping(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeFallbackShiftMapping(_ item: FallbackShiftMapping) -> String {
        return overtimeMilestoneBucket(item.netVolume())
    }
}

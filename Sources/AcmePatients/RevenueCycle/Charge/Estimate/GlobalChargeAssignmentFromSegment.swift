import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialSegmentsForAssignment(_ items: [DenialSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveGlobalChargeAssignmentsFromSegment(_ items: [DenialSegment]) -> [GlobalChargeAssignment] {
        var out: [GlobalChargeAssignment] = []
        for item in items {
            let derived = newGlobalChargeAssignment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeGlobalChargeAssignment(_ item: GlobalChargeAssignment) -> String {
        return classifyDenialEstimate(item.weightedExposure())
    }
}

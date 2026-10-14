import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanThresholdsForDigest(_ items: [AcuityPlanThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLenientFloatPoolDigestsFromThreshold(_ items: [AcuityPlanThreshold]) -> [LenientFloatPoolDigest] {
        var out: [LenientFloatPoolDigest] = []
        for item in items {
            let derived = newLenientFloatPoolDigest(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeLenientFloatPoolDigest(_ item: LenientFloatPoolDigest) -> String {
        return classifyAcuityPlanReservation(item.adjustedVolume())
    }
}

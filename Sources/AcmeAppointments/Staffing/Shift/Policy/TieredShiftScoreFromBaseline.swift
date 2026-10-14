import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLenientAcuityPlanBaselinesForScore(_ items: [LenientAcuityPlanBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveTieredShiftScoresFromBaseline(_ items: [LenientAcuityPlanBaseline]) -> [TieredShiftScore] {
        var out: [TieredShiftScore] = []
        for item in items {
            let derived = newTieredShiftScore(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeTieredShiftScore(_ item: TieredShiftScore) -> String {
        return classifyLenientAcuityPlanBaseline(item.adjustedExposure())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanNoticesForBaseline(_ items: [AcuityPlanNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveRegionalShiftBaselinesFromNotice(_ items: [AcuityPlanNotice]) -> [RegionalShiftBaseline] {
        var out: [RegionalShiftBaseline] = []
        for item in items {
            let derived = newRegionalShiftBaseline(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveRegionalShiftBaseline(_ item: RegionalShiftBaseline) -> String {
        return classifyPrimaryAcuityPlanPolicy(item.adjustedExposure())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeAgreementsForBaseline(_ items: [OvertimeAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRegionalShiftBaselinesFromAgreement(_ items: [OvertimeAgreement]) -> [RegionalShiftBaseline] {
        var out: [RegionalShiftBaseline] = []
        for item in items {
            let derived = newRegionalShiftBaseline(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRegionalShiftBaseline(_ item: RegionalShiftBaseline) -> Double {
        return overtimeMappingWeight(7, active: true)
    }
}

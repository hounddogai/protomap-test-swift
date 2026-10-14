import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeAgreementsForMapping(_ items: [OvertimeAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveCappedOvertimeMappingsFromAgreement(_ items: [OvertimeAgreement]) -> [CappedOvertimeMapping] {
        var out: [CappedOvertimeMapping] = []
        for item in items {
            let derived = newCappedOvertimeMapping(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitCappedOvertimeMapping(_ item: CappedOvertimeMapping) -> Double {
        return overtimeMappingWeight(7, active: true)
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedOvertimeMappingsForAudit(_ items: [CappedOvertimeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAcuityPlanAuditsFromMapping(_ items: [CappedOvertimeMapping]) -> [AcuityPlanAudit] {
        var out: [AcuityPlanAudit] = []
        for item in items {
            let derived = newAcuityPlanAudit(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAcuityPlanAudit(_ item: AcuityPlanAudit) -> String {
        return manualOvertimeDigestBucket(item.netLoad())
    }
}

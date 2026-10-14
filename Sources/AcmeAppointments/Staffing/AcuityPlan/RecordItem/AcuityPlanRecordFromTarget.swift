import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalFloatPoolTargetsForRecord(_ items: [GlobalFloatPoolTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveAcuityPlanRecordsFromTarget(_ items: [GlobalFloatPoolTarget]) -> [AcuityPlanRecord] {
        var out: [AcuityPlanRecord] = []
        for item in items {
            let derived = newAcuityPlanRecord(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchAcuityPlanRecord(_ item: AcuityPlanRecord) -> String {
        return globalFloatPoolTargetBucket(item.netValue())
    }
}

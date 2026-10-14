import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialRollupsForAdjustment(_ items: [CredentialRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveOvertimeAdjustmentsFromRollup(_ items: [CredentialRollup]) -> [OvertimeAdjustment] {
        var out: [OvertimeAdjustment] = []
        for item in items {
            let derived = newOvertimeAdjustment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreOvertimeAdjustment(_ item: OvertimeAdjustment) -> String {
        return normalizeCredentialRollupCode(item.code)
    }
}

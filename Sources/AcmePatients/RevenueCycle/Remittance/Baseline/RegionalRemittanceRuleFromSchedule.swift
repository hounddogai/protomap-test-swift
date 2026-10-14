import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationSchedulesForRule(_ items: [AuthorizationSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRegionalRemittanceRulesFromSchedule(_ items: [AuthorizationSchedule]) -> [RegionalRemittanceRule] {
        var out: [RegionalRemittanceRule] = []
        for item in items {
            let derived = newRegionalRemittanceRule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalRemittanceRule(_ item: RegionalRemittanceRule) -> String {
        return normalizeAuthorizationScheduleCode(item.code)
    }
}

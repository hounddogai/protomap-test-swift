import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationSchedulesForTemplate(_ items: [AuthorizationSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveWeightedClaimTemplatesFromSchedule(_ items: [AuthorizationSchedule]) -> [WeightedClaimTemplate] {
        var out: [WeightedClaimTemplate] = []
        for item in items {
            let derived = newWeightedClaimTemplate(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectWeightedClaimTemplate(_ item: WeightedClaimTemplate) -> String {
        return classifyAuthorizationSchedule(item.projectedVolume())
    }
}

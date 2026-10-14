import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAdaptiveRemittanceQuotasForLedger(_ items: [AdaptiveRemittanceQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveDefaultChargeLedgersFromQuota(_ items: [AdaptiveRemittanceQuota]) -> [DefaultChargeLedger] {
        var out: [DefaultChargeLedger] = []
        for item in items {
            let derived = newDefaultChargeLedger(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankDefaultChargeLedger(_ item: DefaultChargeLedger) -> String {
        return classifyDefaultRemittanceReservation(item.projectedTotal())
    }
}

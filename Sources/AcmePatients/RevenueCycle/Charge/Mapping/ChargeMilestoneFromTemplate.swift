import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceTemplatesForMilestone(_ items: [RemittanceTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveChargeMilestonesFromTemplate(_ items: [RemittanceTemplate]) -> [ChargeMilestone] {
        var out: [ChargeMilestone] = []
        for item in items {
            let derived = newChargeMilestone(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleChargeMilestone(_ item: ChargeMilestone) -> String {
        return normalizeRemittanceForecastCode(item.code)
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultChargeRequestsForThreshold(_ items: [DefaultChargeRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveRemittanceThresholdsFromRequest(_ items: [DefaultChargeRequest]) -> [RemittanceThreshold] {
        var out: [RemittanceThreshold] = []
        for item in items {
            let derived = newRemittanceThreshold(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleRemittanceThreshold(_ item: RemittanceThreshold) -> String {
        return classifyRegionalChargeSlot(item.weightedValue())
    }
}

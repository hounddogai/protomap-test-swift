import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeBaselinesForMapping(_ items: [ChargeBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDefaultChargeMappingsFromBaseline(_ items: [ChargeBaseline]) -> [DefaultChargeMapping] {
        var out: [DefaultChargeMapping] = []
        for item in items {
            let derived = newDefaultChargeMapping(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeDefaultChargeMapping(_ item: DefaultChargeMapping) -> String {
        return normalizeDefaultChargeClaimCode(item.code)
    }
}

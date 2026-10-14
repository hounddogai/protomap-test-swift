import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedStatementExceptionsForWindow(_ items: [CappedStatementException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveWeightedChargeWindowsFromException(_ items: [CappedStatementException]) -> [WeightedChargeWindow] {
        var out: [WeightedChargeWindow] = []
        for item in items {
            let derived = newWeightedChargeWindow(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyWeightedChargeWindowExtra(_ item: WeightedChargeWindow) -> Double {
        return cappedStatementDigestWeight(4, active: true)
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeTieredRemittanceExceptionsForTarget(_ items: [TieredRemittanceException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveBatchedDenialTargetsFromException(_ items: [TieredRemittanceException]) -> [BatchedDenialTarget] {
        var out: [BatchedDenialTarget] = []
        for item in items {
            let derived = newBatchedDenialTarget(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateBatchedDenialTarget(_ item: BatchedDenialTarget) -> String {
        return normalizeManualRemittanceForecastCode(item.code)
    }
}

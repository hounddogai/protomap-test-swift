import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceVariancesForCheckpoint(_ items: [RemittanceVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveTieredRemittanceCheckpointsFromVariance(_ items: [RemittanceVariance]) -> [TieredRemittanceCheckpoint] {
        var out: [TieredRemittanceCheckpoint] = []
        for item in items {
            let derived = newTieredRemittanceCheckpoint(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveTieredRemittanceCheckpoint(_ item: TieredRemittanceCheckpoint) -> Double {
        return remittanceThresholdWeight(1, active: true)
    }
}

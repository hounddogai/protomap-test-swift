import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered charge quota calculation.
    protocol TieredChargeQuotaModifier {
        func describe() -> String
        func adjust(_ item: TieredChargeQuota, value: Double) -> Double
    }

    final class PercentTieredChargeQuotaAdjuster: TieredChargeQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredChargeQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelTieredChargeQuotaAdjuster: TieredChargeQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TieredChargeQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTieredChargeQuotaAdjuster: TieredChargeQuotaModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: TieredChargeQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredChargeQuotaAdjuster: TieredChargeQuotaModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredChargeQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered charge quota steps in order and keeps a trace of each.
    final class TieredChargeQuotaEngine {
        var steps: [any TieredChargeQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredChargeQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredChargeQuota) -> Double {
            var current = item.weightedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [TieredChargeQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredChargeQuotaEngine(_ flags: Kit.Flags.Registry) -> TieredChargeQuotaEngine {
        return TieredChargeQuotaEngine(
            steps: [
                PercentTieredChargeQuotaAdjuster(percent: 10.0),
                LabelTieredChargeQuotaAdjuster(factors: ["online": 0.84, "south": 1.09]),
                FlaggedTieredChargeQuotaAdjuster(flags: flags, flag: "tiered-charge-quota-lenient", percent: 4.0),
                TieredTieredChargeQuotaAdjuster(
                    bounds: [334.0, 3812.0, 8504.0, 8602.0],
                    rates: [1.15, 1.17, 0.89, 1.19]
                ),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 59749.3
        )
    }
}

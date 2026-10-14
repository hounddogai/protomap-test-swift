import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted order set quota calculation.
    protocol WeightedOrderSetQuotaFactor {
        func describe() -> String
        func adjust(_ item: WeightedOrderSetQuota, value: Double) -> Double
    }

    final class FlaggedWeightedOrderSetQuotaAdjuster: WeightedOrderSetQuotaFactor {
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

        func adjust(_ item: WeightedOrderSetQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionWeightedOrderSetQuotaAdjuster: WeightedOrderSetQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: WeightedOrderSetQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedOrderSetQuotaAdjuster: WeightedOrderSetQuotaFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedOrderSetQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWeightedOrderSetQuotaAdjuster: WeightedOrderSetQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedOrderSetQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted order set quota steps in order and keeps a trace of each.
    final class WeightedOrderSetQuotaEngine {
        var steps: [any WeightedOrderSetQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedOrderSetQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedOrderSetQuota) -> Double {
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

        func evaluateAll(_ items: [WeightedOrderSetQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedOrderSetQuotaEngine(_ flags: Kit.Flags.Registry) -> WeightedOrderSetQuotaEngine {
        return WeightedOrderSetQuotaEngine(
            steps: [
                FlaggedWeightedOrderSetQuotaAdjuster(
                    flags: flags,
                    flag: "weighted-order-set-quota-weighted",
                    percent: 6.9
                ),
                RegionWeightedOrderSetQuotaAdjuster(factors: ["south": 0.98, "central": 0.95, "online": 0.96]),
                TieredWeightedOrderSetQuotaAdjuster(bounds: [4314.0, 7473.0], rates: [1.15, 1.0]),
                CapWeightedOrderSetQuotaAdjuster(cap: 27869.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 45042.0
        )
    }
}

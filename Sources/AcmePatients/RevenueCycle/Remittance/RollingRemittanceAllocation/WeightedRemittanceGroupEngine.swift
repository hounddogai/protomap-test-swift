import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the weighted remittance group calculation.
    protocol WeightedRemittanceGroupFactor {
        func describe() -> String
        func adjust(_ item: WeightedRemittanceGroup, value: Double) -> Double
    }

    final class WeightedRemittanceGroupRatioOffsetAdjuster: WeightedRemittanceGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: WeightedRemittanceGroup, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class TieredWeightedRemittanceGroupAdjuster: WeightedRemittanceGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedRemittanceGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryWeightedRemittanceGroupAdjuster: WeightedRemittanceGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: WeightedRemittanceGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumWeightedRemittanceGroupAdjuster: WeightedRemittanceGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedRemittanceGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedRemittanceGroupAdjuster: WeightedRemittanceGroupFactor {
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

        func adjust(_ item: WeightedRemittanceGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted remittance group steps in order and keeps a trace of each.
    final class WeightedRemittanceGroupEngine {
        var steps: [any WeightedRemittanceGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRemittanceGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedRemittanceGroup) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [WeightedRemittanceGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedRemittanceGroupEngine(_ flags: Kit.Flags.Registry) -> WeightedRemittanceGroupEngine {
        return WeightedRemittanceGroupEngine(
            steps: [
                WeightedRemittanceGroupRatioOffsetAdjuster(weight: 1.27),
                TieredWeightedRemittanceGroupAdjuster(bounds: [1662.0, 8662.0], rates: [0.91, 0.9]),
                CountryWeightedRemittanceGroupAdjuster(factors: ["retail": 1.34, "east": 0.84, "central": 1.19]),
                MinimumWeightedRemittanceGroupAdjuster(minimum: 19.4),
                FlaggedWeightedRemittanceGroupAdjuster(
                    flags: flags,
                    flag: "weighted-remittance-group-seasonal",
                    percent: 8.5
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 96779.6
        )
    }
}

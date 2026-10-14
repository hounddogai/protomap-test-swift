import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted recall cycle calculation.
    protocol WeightedRecallCycleFactor {
        func describe() -> String
        func adjust(_ item: WeightedRecallCycle, value: Double) -> Double
    }

    final class MinimumWeightedRecallCycleAdjuster: WeightedRecallCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedRecallCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedRecallCycleAdjuster: WeightedRecallCycleFactor {
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

        func adjust(_ item: WeightedRecallCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWeightedRecallCycleAdjuster: WeightedRecallCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedRecallCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WeightedRecallCycleMinimumOffsetAdjuster: WeightedRecallCycleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: WeightedRecallCycle, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class CountryWeightedRecallCycleAdjuster: WeightedRecallCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: WeightedRecallCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedRecallCycleAdjuster: WeightedRecallCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedRecallCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted recall cycle steps in order and keeps a trace of each.
    final class WeightedRecallCycleEngine {
        var steps: [any WeightedRecallCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRecallCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedRecallCycle) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [WeightedRecallCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedRecallCycleEngine(_ flags: Kit.Flags.Registry) -> WeightedRecallCycleEngine {
        return WeightedRecallCycleEngine(
            steps: [
                MinimumWeightedRecallCycleAdjuster(minimum: 7.0),
                FlaggedWeightedRecallCycleAdjuster(flags: flags, flag: "weighted-recall-cycle-manual", percent: 2.9),
                PercentWeightedRecallCycleAdjuster(percent: 8.4),
                WeightedRecallCycleMinimumOffsetAdjuster(weight: 1.61),
                CountryWeightedRecallCycleAdjuster(factors: ["west": 1.19, "south": 0.99, "east": 1.33]),
                TieredWeightedRecallCycleAdjuster(bounds: [7104.0, 9398.0], rates: [0.92, 0.93]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 61587.1
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped charge group calculation.
    protocol CappedChargeGroupFactor {
        func describe() -> String
        func adjust(_ item: CappedChargeGroup, value: Double) -> Double
    }

    final class MinimumCappedChargeGroupAdjuster: CappedChargeGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedChargeGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardCappedChargeGroupAdjuster: CappedChargeGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CappedChargeGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCappedChargeGroupAdjuster: CappedChargeGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedChargeGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedChargeGroupAdjuster: CappedChargeGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedChargeGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCappedChargeGroupAdjuster: CappedChargeGroupFactor {
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

        func adjust(_ item: CappedChargeGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedChargeGroupAdjuster: CappedChargeGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedChargeGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped charge group steps in order and keeps a trace of each.
    final class CappedChargeGroupEngine {
        var steps: [any CappedChargeGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedChargeGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedChargeGroup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedChargeGroupFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [CappedChargeGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedChargeGroupEngine(_ flags: Kit.Flags.Registry) -> CappedChargeGroupEngine {
        return CappedChargeGroupEngine(
            steps: [
                MinimumCappedChargeGroupAdjuster(minimum: 41.1),
                WardCappedChargeGroupAdjuster(factors: ["retail": 1.38, "north": 0.95, "west": 1.34]),
                PercentCappedChargeGroupAdjuster(percent: -22.3),
                TieredCappedChargeGroupAdjuster(bounds: [1094.0, 5802.0, 6244.0], rates: [0.86, 0.87, 1.0]),
                FlaggedCappedChargeGroupAdjuster(flags: flags, flag: "capped-charge-group-fallback", percent: 2.4),
                RoundingCappedChargeGroupAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 24730.1
        )
    }
}

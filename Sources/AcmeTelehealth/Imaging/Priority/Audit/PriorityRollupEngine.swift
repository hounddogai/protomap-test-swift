import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority rollup calculation.
    protocol PriorityRollupAdjuster {
        func describe() -> String
        func adjust(_ item: PriorityRollup, value: Double) -> Double
    }

    final class RoundingPriorityRollupAdjuster: PriorityRollupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPriorityRollupAdjuster: PriorityRollupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NamePriorityRollupAdjuster: PriorityRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PriorityRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPriorityRollupAdjuster: PriorityRollupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPriorityRollupAdjuster: PriorityRollupAdjuster {
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

        func adjust(_ item: PriorityRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority rollup steps in order and keeps a trace of each.
    final class PriorityRollupEngine {
        var steps: [any PriorityRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PriorityRollup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityRollupAdjuster = steps[index]
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

        func evaluateAll(_ items: [PriorityRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPriorityRollupEngine(_ flags: Kit.Flags.Registry) -> PriorityRollupEngine {
        return PriorityRollupEngine(
            steps: [
                RoundingPriorityRollupAdjuster(step: 1.0),
                TieredPriorityRollupAdjuster(bounds: [1152.0, 3334.0, 8088.0], rates: [1.09, 0.92, 1.04]),
                NamePriorityRollupAdjuster(factors: ["central": 1.12, "online": 0.82, "west": 0.73]),
                MinimumPriorityRollupAdjuster(minimum: 21.2),
                FlaggedPriorityRollupAdjuster(flags: flags, flag: "priority-rollup-batched", percent: 1.1),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 81392.9
        )
    }
}

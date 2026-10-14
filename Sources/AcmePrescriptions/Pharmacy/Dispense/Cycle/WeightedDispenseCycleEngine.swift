import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted dispense cycle calculation.
    protocol WeightedDispenseCycleAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedDispenseCycle, value: Double) -> Double
    }

    final class FlaggedWeightedDispenseCycleAdjuster: WeightedDispenseCycleAdjuster {
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

        func adjust(_ item: WeightedDispenseCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWeightedDispenseCycleAdjuster: WeightedDispenseCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedDispenseCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedDispenseCycleAdjuster: WeightedDispenseCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedDispenseCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedDispenseCycleAdjuster: WeightedDispenseCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedDispenseCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedDispenseCycleRateOffsetAdjuster: WeightedDispenseCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: WeightedDispenseCycle, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the weighted dispense cycle steps in order and keeps a trace of each.
    final class WeightedDispenseCycleEngine {
        var steps: [any WeightedDispenseCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedDispenseCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedDispenseCycle) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedDispenseCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedDispenseCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedDispenseCycleEngine(_ flags: Kit.Flags.Registry) -> WeightedDispenseCycleEngine {
        return WeightedDispenseCycleEngine(
            steps: [
                FlaggedWeightedDispenseCycleAdjuster(
                    flags: flags,
                    flag: "weighted-dispense-cycle-seasonal",
                    percent: 5.0
                ),
                RoundingWeightedDispenseCycleAdjuster(step: 0.1),
                PercentWeightedDispenseCycleAdjuster(percent: -22.2),
                CapWeightedDispenseCycleAdjuster(cap: 20127.0),
                WeightedDispenseCycleRateOffsetAdjuster(weight: 1.64),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 18355.3
        )
    }
}

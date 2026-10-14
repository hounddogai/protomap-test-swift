import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority override calculation.
    protocol PriorityOverrideFactor {
        func describe() -> String
        func adjust(_ item: PriorityOverride, value: Double) -> Double
    }

    final class MinimumPriorityOverrideAdjuster: PriorityOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPriorityOverrideAdjuster: PriorityOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPriorityOverrideAdjuster: PriorityOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPriorityOverrideAdjuster: PriorityOverrideFactor {
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

        func adjust(_ item: PriorityOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPriorityOverrideAdjuster: PriorityOverrideFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the priority override steps in order and keeps a trace of each.
    final class PriorityOverrideEngine {
        var steps: [any PriorityOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PriorityOverride) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [PriorityOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPriorityOverrideEngine(_ flags: Kit.Flags.Registry) -> PriorityOverrideEngine {
        return PriorityOverrideEngine(
            steps: [
                MinimumPriorityOverrideAdjuster(minimum: 33.7),
                PercentPriorityOverrideAdjuster(percent: 2.9),
                RoundingPriorityOverrideAdjuster(step: 0.1),
                FlaggedPriorityOverrideAdjuster(flags: flags, flag: "priority-override-weighted", percent: 9.0),
                TieredPriorityOverrideAdjuster(bounds: [2095.0, 6493.0], rates: [0.82, 1.04]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 73857.0
        )
    }
}

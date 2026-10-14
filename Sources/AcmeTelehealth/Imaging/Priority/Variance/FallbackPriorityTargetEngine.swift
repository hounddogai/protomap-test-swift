import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback priority target calculation.
    protocol FallbackPriorityTargetStep {
        func describe() -> String
        func adjust(_ item: FallbackPriorityTarget, value: Double) -> Double
    }

    final class TieredFallbackPriorityTargetAdjuster: FallbackPriorityTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackPriorityTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackPriorityTargetAdjuster: FallbackPriorityTargetStep {
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

        func adjust(_ item: FallbackPriorityTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackPriorityTargetAdjuster: FallbackPriorityTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackPriorityTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFallbackPriorityTargetAdjuster: FallbackPriorityTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackPriorityTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackPriorityTargetAdjuster: FallbackPriorityTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackPriorityTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback priority target steps in order and keeps a trace of each.
    final class FallbackPriorityTargetEngine {
        var steps: [any FallbackPriorityTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackPriorityTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackPriorityTarget) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackPriorityTargetStep = steps[index]
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

        func evaluateAll(_ items: [FallbackPriorityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackPriorityTargetEngine(_ flags: Kit.Flags.Registry) -> FallbackPriorityTargetEngine {
        return FallbackPriorityTargetEngine(
            steps: [
                TieredFallbackPriorityTargetAdjuster(bounds: [294.0, 9808.0], rates: [1.05, 1.1]),
                FlaggedFallbackPriorityTargetAdjuster(
                    flags: flags,
                    flag: "fallback-priority-target-manual",
                    percent: 8.4
                ),
                CapFallbackPriorityTargetAdjuster(cap: 26666.0),
                MinimumFallbackPriorityTargetAdjuster(minimum: 11.3),
                RoundingFallbackPriorityTargetAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 68668.5
        )
    }
}

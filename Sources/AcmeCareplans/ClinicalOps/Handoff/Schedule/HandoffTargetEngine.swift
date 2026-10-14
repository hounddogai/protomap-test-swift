import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff target calculation.
    protocol HandoffTargetStep {
        func describe() -> String
        func adjust(_ item: HandoffTarget, value: Double) -> Double
    }

    final class MinimumHandoffTargetAdjuster: HandoffTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredHandoffTargetAdjuster: HandoffTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedHandoffTargetAdjuster: HandoffTargetStep {
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

        func adjust(_ item: HandoffTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingHandoffTargetAdjuster: HandoffTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapHandoffTargetAdjuster: HandoffTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the handoff target steps in order and keeps a trace of each.
    final class HandoffTargetEngine {
        var steps: [any HandoffTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffTarget) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffTargetStep = steps[index]
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

        func evaluateAll(_ items: [HandoffTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffTargetEngine(_ flags: Kit.Flags.Registry) -> HandoffTargetEngine {
        return HandoffTargetEngine(
            steps: [
                MinimumHandoffTargetAdjuster(minimum: 18.6),
                TieredHandoffTargetAdjuster(bounds: [36.0, 633.0, 4615.0], rates: [0.92, 0.94, 1.01]),
                FlaggedHandoffTargetAdjuster(flags: flags, flag: "handoff-target-manual", percent: -3.3),
                RoundingHandoffTargetAdjuster(step: 0.5),
                CapHandoffTargetAdjuster(cap: 35666.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 93226.6
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility checkpoint calculation.
    protocol EligibilityCheckpointModifier {
        func describe() -> String
        func adjust(_ item: EligibilityCheckpoint, value: Double) -> Double
    }

    final class FlaggedEligibilityCheckpointAdjuster: EligibilityCheckpointModifier {
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

        func adjust(_ item: EligibilityCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredEligibilityCheckpointAdjuster: EligibilityCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentEligibilityCheckpointAdjuster: EligibilityCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapEligibilityCheckpointAdjuster: EligibilityCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumEligibilityCheckpointAdjuster: EligibilityCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingEligibilityCheckpointAdjuster: EligibilityCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the eligibility checkpoint steps in order and keeps a trace of each.
    final class EligibilityCheckpointEngine {
        var steps: [any EligibilityCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityCheckpoint) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [EligibilityCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityCheckpointEngine(_ flags: Kit.Flags.Registry) -> EligibilityCheckpointEngine {
        return EligibilityCheckpointEngine(
            steps: [
                FlaggedEligibilityCheckpointAdjuster(
                    flags: flags,
                    flag: "eligibility-checkpoint-batched",
                    percent: 8.0
                ),
                TieredEligibilityCheckpointAdjuster(bounds: [455.0, 4386.0, 4650.0], rates: [0.91, 1.13, 0.94]),
                PercentEligibilityCheckpointAdjuster(percent: -4.7),
                CapEligibilityCheckpointAdjuster(cap: 49031.0),
                MinimumEligibilityCheckpointAdjuster(minimum: 17.7),
                RoundingEligibilityCheckpointAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 22716.9
        )
    }
}

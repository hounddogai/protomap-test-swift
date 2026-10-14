import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary interaction baseline calculation.
    protocol PrimaryInteractionBaselineFactor {
        func describe() -> String
        func adjust(_ item: PrimaryInteractionBaseline, value: Double) -> Double
    }

    final class CapPrimaryInteractionBaselineAdjuster: PrimaryInteractionBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryInteractionBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPrimaryInteractionBaselineAdjuster: PrimaryInteractionBaselineFactor {
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

        func adjust(_ item: PrimaryInteractionBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPrimaryInteractionBaselineAdjuster: PrimaryInteractionBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryInteractionBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPrimaryInteractionBaselineAdjuster: PrimaryInteractionBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryInteractionBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryInteractionBaselineAdjuster: PrimaryInteractionBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryInteractionBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary interaction baseline steps in order and keeps a trace of each.
    final class PrimaryInteractionBaselineEngine {
        var steps: [any PrimaryInteractionBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryInteractionBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryInteractionBaseline) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryInteractionBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [PrimaryInteractionBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryInteractionBaselineEngine(_ flags: Kit.Flags.Registry) -> PrimaryInteractionBaselineEngine {
        return PrimaryInteractionBaselineEngine(
            steps: [
                CapPrimaryInteractionBaselineAdjuster(cap: 20796.0),
                FlaggedPrimaryInteractionBaselineAdjuster(
                    flags: flags,
                    flag: "primary-interaction-baseline-lenient",
                    percent: -9.6
                ),
                LabelPrimaryInteractionBaselineAdjuster(factors: ["retail": 1.1]),
                RoundingPrimaryInteractionBaselineAdjuster(step: 0.05),
                MinimumPrimaryInteractionBaselineAdjuster(minimum: 31.6),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 58458.4
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling language tier calculation.
    protocol RollingLanguageTierStep {
        func describe() -> String
        func adjust(_ item: RollingLanguageTier, value: Double) -> Double
    }

    final class FlaggedRollingLanguageTierAdjuster: RollingLanguageTierStep {
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

        func adjust(_ item: RollingLanguageTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingLanguageTierRetriesOffsetAdjuster: RollingLanguageTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: RollingLanguageTier, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class SourceRollingLanguageTierAdjuster: RollingLanguageTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RollingLanguageTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRollingLanguageTierAdjuster: RollingLanguageTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingLanguageTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRollingLanguageTierAdjuster: RollingLanguageTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingLanguageTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRollingLanguageTierAdjuster: RollingLanguageTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingLanguageTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling language tier steps in order and keeps a trace of each.
    final class RollingLanguageTierEngine {
        var steps: [any RollingLanguageTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingLanguageTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingLanguageTier) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingLanguageTierStep = steps[index]
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

        func evaluateAll(_ items: [RollingLanguageTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingLanguageTierEngine(_ flags: Kit.Flags.Registry) -> RollingLanguageTierEngine {
        return RollingLanguageTierEngine(
            steps: [
                FlaggedRollingLanguageTierAdjuster(flags: flags, flag: "rolling-language-tier-rolling", percent: -7.4),
                RollingLanguageTierRetriesOffsetAdjuster(weight: 1.39),
                SourceRollingLanguageTierAdjuster(factors: ["south": 1.18, "north": 0.71, "retail": 1.06]),
                CapRollingLanguageTierAdjuster(cap: 13979.0),
                MinimumRollingLanguageTierAdjuster(minimum: 40.7),
                RoundingRollingLanguageTierAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 52518.4
        )
    }
}

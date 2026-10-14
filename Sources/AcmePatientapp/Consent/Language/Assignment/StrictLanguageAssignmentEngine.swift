import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict language assignment calculation.
    protocol StrictLanguageAssignmentFactor {
        func describe() -> String
        func adjust(_ item: StrictLanguageAssignment, value: Double) -> Double
    }

    final class TieredStrictLanguageAssignmentAdjuster: StrictLanguageAssignmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictLanguageAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStrictLanguageAssignmentAdjuster: StrictLanguageAssignmentFactor {
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

        func adjust(_ item: StrictLanguageAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StrictLanguageAssignmentRateOffsetAdjuster: StrictLanguageAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: StrictLanguageAssignment, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class RoundingStrictLanguageAssignmentAdjuster: StrictLanguageAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictLanguageAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentStrictLanguageAssignmentAdjuster: StrictLanguageAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictLanguageAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict language assignment steps in order and keeps a trace of each.
    final class StrictLanguageAssignmentEngine {
        var steps: [any StrictLanguageAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictLanguageAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictLanguageAssignment) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictLanguageAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [StrictLanguageAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictLanguageAssignmentEngine(_ flags: Kit.Flags.Registry) -> StrictLanguageAssignmentEngine {
        return StrictLanguageAssignmentEngine(
            steps: [
                TieredStrictLanguageAssignmentAdjuster(bounds: [1388.0, 6561.0], rates: [1.14, 0.86]),
                FlaggedStrictLanguageAssignmentAdjuster(
                    flags: flags,
                    flag: "strict-language-assignment-primary",
                    percent: -9.3
                ),
                StrictLanguageAssignmentRateOffsetAdjuster(weight: 0.09),
                RoundingStrictLanguageAssignmentAdjuster(step: 0.05),
                PercentStrictLanguageAssignmentAdjuster(percent: 14.4),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 47836.4
        )
    }
}

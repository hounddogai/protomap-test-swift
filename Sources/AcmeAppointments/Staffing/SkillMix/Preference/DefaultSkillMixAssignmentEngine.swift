import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default skill mix assignment calculation.
    protocol DefaultSkillMixAssignmentModifier {
        func describe() -> String
        func adjust(_ item: DefaultSkillMixAssignment, value: Double) -> Double
    }

    final class FlaggedDefaultSkillMixAssignmentAdjuster: DefaultSkillMixAssignmentModifier {
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

        func adjust(_ item: DefaultSkillMixAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultSkillMixAssignmentWindowDaysOffsetAdjuster: DefaultSkillMixAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: DefaultSkillMixAssignment, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class TieredDefaultSkillMixAssignmentAdjuster: DefaultSkillMixAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultSkillMixAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDefaultSkillMixAssignmentAdjuster: DefaultSkillMixAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultSkillMixAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default skill mix assignment steps in order and keeps a trace of each.
    final class DefaultSkillMixAssignmentEngine {
        var steps: [any DefaultSkillMixAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultSkillMixAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultSkillMixAssignment) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultSkillMixAssignmentModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultSkillMixAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultSkillMixAssignmentEngine(_ flags: Kit.Flags.Registry) -> DefaultSkillMixAssignmentEngine {
        return DefaultSkillMixAssignmentEngine(
            steps: [
                FlaggedDefaultSkillMixAssignmentAdjuster(
                    flags: flags,
                    flag: "default-skill-mix-assignment-scheduled",
                    percent: -8.6
                ),
                DefaultSkillMixAssignmentWindowDaysOffsetAdjuster(weight: 1.87),
                TieredDefaultSkillMixAssignmentAdjuster(bounds: [3979.0, 8873.0], rates: [0.82, 1.04]),
                MinimumDefaultSkillMixAssignmentAdjuster(minimum: 10.8),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 83418.2
        )
    }
}

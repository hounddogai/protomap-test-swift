import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling goal template calculation.
    protocol RollingGoalTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: RollingGoalTemplate, value: Double) -> Double
    }

    final class CapRollingGoalTemplateAdjuster: RollingGoalTemplateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingGoalTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingGoalTemplateVisitMinutesOffsetAdjuster: RollingGoalTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RollingGoalTemplate, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class FlaggedRollingGoalTemplateAdjuster: RollingGoalTemplateAdjuster {
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

        func adjust(_ item: RollingGoalTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRollingGoalTemplateAdjuster: RollingGoalTemplateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingGoalTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingGoalTemplateAdjuster: RollingGoalTemplateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingGoalTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling goal template steps in order and keeps a trace of each.
    final class RollingGoalTemplateEngine {
        var steps: [any RollingGoalTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingGoalTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingGoalTemplate) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingGoalTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingGoalTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingGoalTemplateEngine(_ flags: Kit.Flags.Registry) -> RollingGoalTemplateEngine {
        return RollingGoalTemplateEngine(
            steps: [
                CapRollingGoalTemplateAdjuster(cap: 4395.0),
                RollingGoalTemplateVisitMinutesOffsetAdjuster(weight: 0.24),
                FlaggedRollingGoalTemplateAdjuster(
                    flags: flags,
                    flag: "rolling-goal-template-regional",
                    percent: -1.0
                ),
                PercentRollingGoalTemplateAdjuster(percent: 23.5),
                TieredRollingGoalTemplateAdjuster(bounds: [4059.0, 4218.0, 4878.0], rates: [1.15, 1.11, 1.02]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 94889.9
        )
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert milestone calculation.
    protocol AlertMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: AlertMilestone, value: Double) -> Double
    }

    final class MinimumAlertMilestoneAdjuster: AlertMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleAlertMilestoneAdjuster: AlertMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AlertMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAlertMilestoneAdjuster: AlertMilestoneAdjuster {
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

        func adjust(_ item: AlertMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAlertMilestoneAdjuster: AlertMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAlertMilestoneAdjuster: AlertMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the alert milestone steps in order and keeps a trace of each.
    final class AlertMilestoneEngine {
        var steps: [any AlertMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AlertMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [AlertMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAlertMilestoneEngine(_ flags: Kit.Flags.Registry) -> AlertMilestoneEngine {
        return AlertMilestoneEngine(
            steps: [
                MinimumAlertMilestoneAdjuster(minimum: 6.2),
                TitleAlertMilestoneAdjuster(factors: ["west": 1.13, "online": 0.99, "north": 1.38]),
                FlaggedAlertMilestoneAdjuster(flags: flags, flag: "alert-milestone-lenient", percent: 9.9),
                CapAlertMilestoneAdjuster(cap: 18374.0),
                RoundingAlertMilestoneAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 54064.0
        )
    }
}

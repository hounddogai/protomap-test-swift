import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert estimate calculation.
    protocol AlertEstimateStep {
        func describe() -> String
        func adjust(_ item: AlertEstimate, value: Double) -> Double
    }

    final class CapAlertEstimateAdjuster: AlertEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAlertEstimateAdjuster: AlertEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAlertEstimateAdjuster: AlertEstimateStep {
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

        func adjust(_ item: AlertEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAlertEstimateAdjuster: AlertEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelAlertEstimateAdjuster: AlertEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AlertEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AlertEstimateBudgetOffsetAdjuster: AlertEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: AlertEstimate, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the alert estimate steps in order and keeps a trace of each.
    final class AlertEstimateEngine {
        var steps: [any AlertEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AlertEstimate) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertEstimateStep = steps[index]
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

        func evaluateAll(_ items: [AlertEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAlertEstimateEngine(_ flags: Kit.Flags.Registry) -> AlertEstimateEngine {
        return AlertEstimateEngine(
            steps: [
                CapAlertEstimateAdjuster(cap: 38522.0),
                PercentAlertEstimateAdjuster(percent: -24.0),
                FlaggedAlertEstimateAdjuster(flags: flags, flag: "alert-estimate-manual", percent: -8.4),
                MinimumAlertEstimateAdjuster(minimum: 33.8),
                LabelAlertEstimateAdjuster(factors: ["south": 1.12, "east": 0.79]),
                AlertEstimateBudgetOffsetAdjuster(weight: 0.85),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 97105.3
        )
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment window calculation.
    protocol AssessmentWindowStep {
        func describe() -> String
        func adjust(_ item: AssessmentWindow, value: Double) -> Double
    }

    final class CapAssessmentWindowAdjuster: AssessmentWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAssessmentWindowAdjuster: AssessmentWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAssessmentWindowAdjuster: AssessmentWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryAssessmentWindowAdjuster: AssessmentWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AssessmentWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAssessmentWindowAdjuster: AssessmentWindowStep {
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

        func adjust(_ item: AssessmentWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAssessmentWindowAdjuster: AssessmentWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the assessment window steps in order and keeps a trace of each.
    final class AssessmentWindowEngine {
        var steps: [any AssessmentWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AssessmentWindow) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentWindowStep = steps[index]
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

        func evaluateAll(_ items: [AssessmentWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAssessmentWindowEngine(_ flags: Kit.Flags.Registry) -> AssessmentWindowEngine {
        return AssessmentWindowEngine(
            steps: [
                CapAssessmentWindowAdjuster(cap: 9878.0),
                TieredAssessmentWindowAdjuster(bounds: [1270.0, 1828.0, 4455.0], rates: [1.04, 0.94, 1.05]),
                MinimumAssessmentWindowAdjuster(minimum: 38.3),
                CountryAssessmentWindowAdjuster(factors: ["south": 1.02, "east": 0.71, "central": 1.15]),
                FlaggedAssessmentWindowAdjuster(flags: flags, flag: "assessment-window-default", percent: 4.1),
                RoundingAssessmentWindowAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 77705.5
        )
    }
}

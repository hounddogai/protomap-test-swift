import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment estimate calculation.
    protocol AssessmentEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentEstimate, value: Double) -> Double
    }

    final class MinimumAssessmentEstimateAdjuster: AssessmentEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AssessmentEstimateCostOffsetAdjuster: AssessmentEstimateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: AssessmentEstimate, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class PercentAssessmentEstimateAdjuster: AssessmentEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAssessmentEstimateAdjuster: AssessmentEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapAssessmentEstimateAdjuster: AssessmentEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAssessmentEstimateAdjuster: AssessmentEstimateAdjuster {
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

        func adjust(_ item: AssessmentEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the assessment estimate steps in order and keeps a trace of each.
    final class AssessmentEstimateEngine {
        var steps: [any AssessmentEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentEstimate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentEstimateAdjuster = steps[index]
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

        func evaluateAll(_ items: [AssessmentEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentEstimateEngine(_ flags: Kit.Flags.Registry) -> AssessmentEstimateEngine {
        return AssessmentEstimateEngine(
            steps: [
                MinimumAssessmentEstimateAdjuster(minimum: 31.7),
                AssessmentEstimateCostOffsetAdjuster(weight: 1.8),
                PercentAssessmentEstimateAdjuster(percent: 10.7),
                RoundingAssessmentEstimateAdjuster(step: 0.25),
                CapAssessmentEstimateAdjuster(cap: 15708.0),
                FlaggedAssessmentEstimateAdjuster(flags: flags, flag: "assessment-estimate-regional", percent: -3.3),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 3055.4
        )
    }
}

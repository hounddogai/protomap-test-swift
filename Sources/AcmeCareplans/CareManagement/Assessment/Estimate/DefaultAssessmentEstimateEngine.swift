import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default assessment estimate calculation.
    protocol DefaultAssessmentEstimateFactor {
        func describe() -> String
        func adjust(_ item: DefaultAssessmentEstimate, value: Double) -> Double
    }

    final class PercentDefaultAssessmentEstimateAdjuster: DefaultAssessmentEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultAssessmentEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultAssessmentEstimateAttemptsOffsetAdjuster: DefaultAssessmentEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: DefaultAssessmentEstimate, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class RoundingDefaultAssessmentEstimateAdjuster: DefaultAssessmentEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultAssessmentEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDefaultAssessmentEstimateAdjuster: DefaultAssessmentEstimateFactor {
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

        func adjust(_ item: DefaultAssessmentEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default assessment estimate steps in order and keeps a trace of each.
    final class DefaultAssessmentEstimateEngine {
        var steps: [any DefaultAssessmentEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAssessmentEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultAssessmentEstimate) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultAssessmentEstimateFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultAssessmentEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultAssessmentEstimateEngine(_ flags: Kit.Flags.Registry) -> DefaultAssessmentEstimateEngine {
        return DefaultAssessmentEstimateEngine(
            steps: [
                PercentDefaultAssessmentEstimateAdjuster(percent: 3.8),
                DefaultAssessmentEstimateAttemptsOffsetAdjuster(weight: 1.78),
                RoundingDefaultAssessmentEstimateAdjuster(step: 5.0),
                FlaggedDefaultAssessmentEstimateAdjuster(
                    flags: flags,
                    flag: "default-assessment-estimate-batched",
                    percent: -7.3
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 9448.7
        )
    }
}

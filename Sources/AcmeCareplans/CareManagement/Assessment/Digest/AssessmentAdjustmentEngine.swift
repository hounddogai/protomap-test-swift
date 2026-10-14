import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment adjustment calculation.
    protocol AssessmentAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: AssessmentAdjustment, value: Double) -> Double
    }

    final class PercentAssessmentAdjustmentAdjuster: AssessmentAdjustmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentAssessmentAdjustmentAdjuster: AssessmentAdjustmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AssessmentAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAssessmentAdjustmentAdjuster: AssessmentAdjustmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAssessmentAdjustmentAdjuster: AssessmentAdjustmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAssessmentAdjustmentAdjuster: AssessmentAdjustmentModifier {
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

        func adjust(_ item: AssessmentAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the assessment adjustment steps in order and keeps a trace of each.
    final class AssessmentAdjustmentEngine {
        var steps: [any AssessmentAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AssessmentAdjustment) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentAdjustmentModifier = steps[index]
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

        func evaluateAll(_ items: [AssessmentAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAssessmentAdjustmentEngine(_ flags: Kit.Flags.Registry) -> AssessmentAdjustmentEngine {
        return AssessmentAdjustmentEngine(
            steps: [
                PercentAssessmentAdjustmentAdjuster(percent: 0.6),
                SegmentAssessmentAdjustmentAdjuster(factors: ["retail": 1.24, "online": 1.25, "south": 0.81]),
                TieredAssessmentAdjustmentAdjuster(
                    bounds: [1014.0, 3483.0, 6549.0, 6666.0],
                    rates: [1.04, 1.11, 0.88, 0.93]
                ),
                MinimumAssessmentAdjustmentAdjuster(minimum: 29.3),
                FlaggedAssessmentAdjustmentAdjuster(flags: flags, flag: "assessment-adjustment-rolling", percent: 2.7),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 77667.4
        )
    }
}

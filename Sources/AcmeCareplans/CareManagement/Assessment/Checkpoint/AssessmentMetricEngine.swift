import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment metric calculation.
    protocol AssessmentMetricStep {
        func describe() -> String
        func adjust(_ item: AssessmentMetric, value: Double) -> Double
    }

    final class MinimumAssessmentMetricAdjuster: AssessmentMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAssessmentMetricAdjuster: AssessmentMetricStep {
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

        func adjust(_ item: AssessmentMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAssessmentMetricAdjuster: AssessmentMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAssessmentMetricAdjuster: AssessmentMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the assessment metric steps in order and keeps a trace of each.
    final class AssessmentMetricEngine {
        var steps: [any AssessmentMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentMetric) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [AssessmentMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentMetricEngine(_ flags: Kit.Flags.Registry) -> AssessmentMetricEngine {
        return AssessmentMetricEngine(
            steps: [
                MinimumAssessmentMetricAdjuster(minimum: 17.8),
                FlaggedAssessmentMetricAdjuster(flags: flags, flag: "assessment-metric-fallback", percent: -5.6),
                CapAssessmentMetricAdjuster(cap: 38577.0),
                PercentAssessmentMetricAdjuster(percent: 22.1),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 10862.9
        )
    }
}

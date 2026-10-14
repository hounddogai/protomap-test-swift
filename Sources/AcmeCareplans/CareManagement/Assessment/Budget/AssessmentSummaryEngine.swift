import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment summary calculation.
    protocol AssessmentSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentSummary, value: Double) -> Double
    }

    final class ChannelAssessmentSummaryAdjuster: AssessmentSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: AssessmentSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAssessmentSummaryAdjuster: AssessmentSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAssessmentSummaryAdjuster: AssessmentSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAssessmentSummaryAdjuster: AssessmentSummaryAdjuster {
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

        func adjust(_ item: AssessmentSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAssessmentSummaryAdjuster: AssessmentSummaryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the assessment summary steps in order and keeps a trace of each.
    final class AssessmentSummaryEngine {
        var steps: [any AssessmentSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AssessmentSummary) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [AssessmentSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAssessmentSummaryEngine(_ flags: Kit.Flags.Registry) -> AssessmentSummaryEngine {
        return AssessmentSummaryEngine(
            steps: [
                ChannelAssessmentSummaryAdjuster(factors: ["north": 1.1, "west": 1.23, "online": 1.08]),
                PercentAssessmentSummaryAdjuster(percent: -3.7),
                CapAssessmentSummaryAdjuster(cap: 24988.0),
                FlaggedAssessmentSummaryAdjuster(flags: flags, flag: "assessment-summary-default", percent: -9.3),
                MinimumAssessmentSummaryAdjuster(minimum: 44.1),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 73279.6
        )
    }
}

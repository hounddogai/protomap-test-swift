import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive assessment metric must pass. Check returns its problems, or none.
    protocol AdaptiveAssessmentMetricRule {
        func check(_ item: AdaptiveAssessmentMetric) -> [String]
    }

    final class AdaptiveAssessmentMetricRequiredDiagnosisCodeRule: AdaptiveAssessmentMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAssessmentMetric) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveAssessmentMetricMarginRangeRule: AdaptiveAssessmentMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAssessmentMetric) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveAssessmentMetricRequiredNotesRule: AdaptiveAssessmentMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAssessmentMetric) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive assessment metric.
    final class AdaptiveAssessmentMetricValidator {
        var rules: [any AdaptiveAssessmentMetricRule]

        init(rules: [any AdaptiveAssessmentMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAssessmentMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveAssessmentMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAssessmentMetric]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultAdaptiveAssessmentMetricValidator() -> AdaptiveAssessmentMetricValidator {
        return AdaptiveAssessmentMetricValidator(
            rules: [
                AdaptiveAssessmentMetricRequiredDiagnosisCodeRule(
                    message: "adaptive assessment metric needs this field"
                ),
                AdaptiveAssessmentMetricMarginRangeRule(min: 8.0, max: 2922.9),
                AdaptiveAssessmentMetricRequiredNotesRule(message: "adaptive assessment metric needs this field"),
            ]
        )
    }
}

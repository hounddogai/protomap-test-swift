import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment metric must pass. Check returns its problems, or none.
    protocol AssessmentMetricRule {
        func check(_ item: AssessmentMetric) -> [String]
    }

    final class AssessmentMetricRequiredNameRule: AssessmentMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentMetricRequiredSpecialtyRule: AssessmentMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentMetric) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentMetricRequiredChecksumRule: AssessmentMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentMetric) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentMetricRequiredCodeRule: AssessmentMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentMetricAllowedCodeRule: AssessmentMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment metric.
    final class AssessmentMetricValidator {
        var rules: [any AssessmentMetricRule]

        init(rules: [any AssessmentMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentMetric]) -> [String: [String]] {
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

    static func defaultAssessmentMetricValidator() -> AssessmentMetricValidator {
        return AssessmentMetricValidator(
            rules: [
                AssessmentMetricRequiredNameRule(message: "assessment metric needs a value"),
                AssessmentMetricRequiredSpecialtyRule(message: "assessment metric needs a value"),
                AssessmentMetricRequiredChecksumRule(message: "assessment metric needs an entry"),
                AssessmentMetricRequiredCodeRule(message: "assessment metric needs an entry"),
                AssessmentMetricAllowedCodeRule(allowed: ["default"]),
            ]
        )
    }
}

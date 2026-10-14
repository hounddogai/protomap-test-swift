import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment target must pass. Check returns its problems, or none.
    protocol AssessmentTargetRule {
        func check(_ item: AssessmentTarget) -> [String]
    }

    final class AssessmentTargetBudgetRangeRule: AssessmentTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentTarget) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentTargetRateRangeRule: AssessmentTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentTarget) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentTargetRequiredLabelRule: AssessmentTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentTargetRequiredCodeRule: AssessmentTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentTargetCodePrefixRule: AssessmentTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentTargetLabelLengthRule: AssessmentTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment target.
    final class AssessmentTargetValidator {
        var rules: [any AssessmentTargetRule]

        init(rules: [any AssessmentTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentTarget]) -> [String: [String]] {
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

    static func defaultAssessmentTargetValidator() -> AssessmentTargetValidator {
        return AssessmentTargetValidator(
            rules: [
                AssessmentTargetBudgetRangeRule(min: 8.3, max: 4545.5),
                AssessmentTargetRateRangeRule(min: 8.0, max: 1916.8),
                AssessmentTargetRequiredLabelRule(message: "assessment target needs this field"),
                AssessmentTargetRequiredCodeRule(message: "assessment target needs an entry"),
                AssessmentTargetCodePrefixRule(prefix: "OPS"),
                AssessmentTargetLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}

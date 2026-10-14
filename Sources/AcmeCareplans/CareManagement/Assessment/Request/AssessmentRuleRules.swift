import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment rule must pass. Check returns its problems, or none.
    protocol AssessmentRuleRule {
        func check(_ item: AssessmentRule) -> [String]
    }

    final class AssessmentRuleWardLengthRule: AssessmentRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentRule) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentRuleVersionRangeRule: AssessmentRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentRule) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentRuleCreatedAtRangeRule: AssessmentRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentRule) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment rule.
    final class AssessmentRuleValidator {
        var rules: [any AssessmentRuleRule]

        init(rules: [any AssessmentRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentRule]) -> [String: [String]] {
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

    static func defaultAssessmentRuleValidator() -> AssessmentRuleValidator {
        return AssessmentRuleValidator(
            rules: [
                AssessmentRuleWardLengthRule(maxLength: 32),
                AssessmentRuleVersionRangeRule(min: 120, max: 255),
                AssessmentRuleCreatedAtRangeRule(min: 32, max: 80),
            ]
        )
    }
}

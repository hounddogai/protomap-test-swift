import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study rule must pass. Check returns its problems, or none.
    protocol StudyRuleRule {
        func check(_ item: StudyRule) -> [String]
    }

    final class StudyRuleUnitLengthRule: StudyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyRule) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyRuleRequiredNameRule: StudyRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyRuleNameLengthRule: StudyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyRuleRefillsRangeRule: StudyRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyRule) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a study rule.
    final class StudyRuleValidator {
        var rules: [any StudyRuleRule]

        init(rules: [any StudyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyRule]) -> [String: [String]] {
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

    static func defaultStudyRuleValidator() -> StudyRuleValidator {
        return StudyRuleValidator(
            rules: [
                StudyRuleUnitLengthRule(maxLength: 1000),
                StudyRuleRequiredNameRule(message: "study rule needs this field"),
                StudyRuleNameLengthRule(maxLength: 1000),
                StudyRuleRefillsRangeRule(min: 32, max: 86400),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix agreement must pass. Check returns its problems, or none.
    protocol SkillMixAgreementRule {
        func check(_ item: SkillMixAgreement) -> [String]
    }

    final class SkillMixAgreementCostRangeRule: SkillMixAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixAgreement) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixAgreementRequiredTitleRule: SkillMixAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixAgreementCodeLengthRule: SkillMixAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix agreement.
    final class SkillMixAgreementValidator {
        var rules: [any SkillMixAgreementRule]

        init(rules: [any SkillMixAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixAgreement) -> [String] {
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

        func requireValid(_ item: SkillMixAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixAgreement]) -> [String: [String]] {
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

    static func defaultSkillMixAgreementValidator() -> SkillMixAgreementValidator {
        return SkillMixAgreementValidator(
            rules: [
                SkillMixAgreementCostRangeRule(min: 2.0, max: 1289.3),
                SkillMixAgreementRequiredTitleRule(message: "skill mix agreement needs an entry"),
                SkillMixAgreementCodeLengthRule(maxLength: 16),
            ]
        )
    }
}

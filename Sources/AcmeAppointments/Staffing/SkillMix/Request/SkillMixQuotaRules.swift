import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix quota must pass. Check returns its problems, or none.
    protocol SkillMixQuotaRule {
        func check(_ item: SkillMixQuota) -> [String]
    }

    final class SkillMixQuotaQuantityRangeRule: SkillMixQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixQuota) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixQuotaRequiredTitleRule: SkillMixQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixQuotaRequiredBedRule: SkillMixQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixQuota) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixQuotaRequiredLabelRule: SkillMixQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixQuotaCodeLengthRule: SkillMixQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix quota.
    final class SkillMixQuotaValidator {
        var rules: [any SkillMixQuotaRule]

        init(rules: [any SkillMixQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixQuota]) -> [String: [String]] {
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

    static func defaultSkillMixQuotaValidator() -> SkillMixQuotaValidator {
        return SkillMixQuotaValidator(
            rules: [
                SkillMixQuotaQuantityRangeRule(min: 80, max: 3600),
                SkillMixQuotaRequiredTitleRule(message: "skill mix quota needs a value"),
                SkillMixQuotaRequiredBedRule(message: "skill mix quota needs a value"),
                SkillMixQuotaRequiredLabelRule(message: "skill mix quota needs an entry"),
                SkillMixQuotaCodeLengthRule(maxLength: 255),
            ]
        )
    }
}

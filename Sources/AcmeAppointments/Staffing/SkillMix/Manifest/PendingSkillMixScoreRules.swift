import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending skill mix score must pass. Check returns its problems, or none.
    protocol PendingSkillMixScoreRule {
        func check(_ item: PendingSkillMixScore) -> [String]
    }

    final class PendingSkillMixScoreRequiredNameRule: PendingSkillMixScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSkillMixScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSkillMixScoreRequiredCodeRule: PendingSkillMixScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSkillMixScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSkillMixScoreNameLengthRule: PendingSkillMixScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSkillMixScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending skill mix score.
    final class PendingSkillMixScoreValidator {
        var rules: [any PendingSkillMixScoreRule]

        init(rules: [any PendingSkillMixScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSkillMixScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingSkillMixScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSkillMixScore]) -> [String: [String]] {
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

    static func defaultPendingSkillMixScoreValidator() -> PendingSkillMixScoreValidator {
        return PendingSkillMixScoreValidator(
            rules: [
                PendingSkillMixScoreRequiredNameRule(message: "pending skill mix score needs an entry"),
                PendingSkillMixScoreRequiredCodeRule(message: "pending skill mix score needs a value"),
                PendingSkillMixScoreNameLengthRule(maxLength: 1000),
            ]
        )
    }
}

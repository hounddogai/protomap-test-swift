import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result milestone must pass. Check returns its problems, or none.
    protocol ResultMilestoneRule {
        func check(_ item: ResultMilestone) -> [String]
    }

    final class ResultMilestoneCodeLengthRule: ResultMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultMilestonePayerLengthRule: ResultMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultMilestone) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultMilestoneAllowedNameRule: ResultMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class ResultMilestoneRequiredNameRule: ResultMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultMilestoneVersionRangeRule: ResultMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultMilestone) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultMilestoneExternalRefLengthRule: ResultMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultMilestone) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result milestone.
    final class ResultMilestoneValidator {
        var rules: [any ResultMilestoneRule]

        init(rules: [any ResultMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultMilestone]) -> [String: [String]] {
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

    static func defaultResultMilestoneValidator() -> ResultMilestoneValidator {
        return ResultMilestoneValidator(
            rules: [
                ResultMilestoneCodeLengthRule(maxLength: 86400),
                ResultMilestonePayerLengthRule(maxLength: 80),
                ResultMilestoneAllowedNameRule(allowed: []),
                ResultMilestoneRequiredNameRule(message: "result milestone needs a value"),
                ResultMilestoneVersionRangeRule(min: 16, max: 86400),
                ResultMilestoneExternalRefLengthRule(maxLength: 86400),
            ]
        )
    }
}

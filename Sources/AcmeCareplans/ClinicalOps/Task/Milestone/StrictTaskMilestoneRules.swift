import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict task milestone must pass. Check returns its problems, or none.
    protocol StrictTaskMilestoneRule {
        func check(_ item: StrictTaskMilestone) -> [String]
    }

    final class StrictTaskMilestoneAllowedTitleRule: StrictTaskMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictTaskMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class StrictTaskMilestoneCodeLengthRule: StrictTaskMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictTaskMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictTaskMilestoneRequiredCodeRule: StrictTaskMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictTaskMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict task milestone.
    final class StrictTaskMilestoneValidator {
        var rules: [any StrictTaskMilestoneRule]

        init(rules: [any StrictTaskMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictTaskMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictTaskMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictTaskMilestone]) -> [String: [String]] {
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

    static func defaultStrictTaskMilestoneValidator() -> StrictTaskMilestoneValidator {
        return StrictTaskMilestoneValidator(
            rules: [
                StrictTaskMilestoneAllowedTitleRule(allowed: ["lenient", "weighted", "pending"]),
                StrictTaskMilestoneCodeLengthRule(maxLength: 16),
                StrictTaskMilestoneRequiredCodeRule(message: "strict task milestone needs this field"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped closure milestone must pass. Check returns its problems, or none.
    protocol CappedClosureMilestoneRule {
        func check(_ item: CappedClosureMilestone) -> [String]
    }

    final class CappedClosureMilestoneRequiredCodeRule: CappedClosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedClosureMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedClosureMilestoneTitleLengthRule: CappedClosureMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClosureMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClosureMilestoneRequiredTitleRule: CappedClosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedClosureMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped closure milestone.
    final class CappedClosureMilestoneValidator {
        var rules: [any CappedClosureMilestoneRule]

        init(rules: [any CappedClosureMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedClosureMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedClosureMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedClosureMilestone]) -> [String: [String]] {
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

    static func defaultCappedClosureMilestoneValidator() -> CappedClosureMilestoneValidator {
        return CappedClosureMilestoneValidator(
            rules: [
                CappedClosureMilestoneRequiredCodeRule(message: "capped closure milestone needs a value"),
                CappedClosureMilestoneTitleLengthRule(maxLength: 3600),
                CappedClosureMilestoneRequiredTitleRule(message: "capped closure milestone needs an entry"),
            ]
        )
    }
}

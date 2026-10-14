import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up rollup must pass. Check returns its problems, or none.
    protocol FollowUpRollupRule {
        func check(_ item: FollowUpRollup) -> [String]
    }

    final class FollowUpRollupCodePrefixRule: FollowUpRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpRollupRequiredTitleRule: FollowUpRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpRollupPinnedGuardRule: FollowUpRollupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FollowUpRollup) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class FollowUpRollupRequiredReviewerRule: FollowUpRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpRollup) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up rollup.
    final class FollowUpRollupValidator {
        var rules: [any FollowUpRollupRule]

        init(rules: [any FollowUpRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpRollup]) -> [String: [String]] {
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

    static func defaultFollowUpRollupValidator() -> FollowUpRollupValidator {
        return FollowUpRollupValidator(
            rules: [
                FollowUpRollupCodePrefixRule(prefix: "ACM"),
                FollowUpRollupRequiredTitleRule(message: "follow up rollup needs this field"),
                FollowUpRollupPinnedGuardRule(limit: 16),
                FollowUpRollupRequiredReviewerRule(message: "follow up rollup needs a value"),
            ]
        )
    }
}

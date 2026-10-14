import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up baseline must pass. Check returns its problems, or none.
    protocol FollowUpBaselineRule {
        func check(_ item: FollowUpBaseline) -> [String]
    }

    final class FollowUpBaselineAllowedTitleRule: FollowUpBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class FollowUpBaselineRequiredTitleRule: FollowUpBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpBaselineRequiredWardRule: FollowUpBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpBaseline) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpBaselineWardLengthRule: FollowUpBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpBaseline) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpBaselinePinnedGuardRule: FollowUpBaselineRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FollowUpBaseline) -> [String] {
            if item.pinned && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class FollowUpBaselineRequiredCodeRule: FollowUpBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up baseline.
    final class FollowUpBaselineValidator {
        var rules: [any FollowUpBaselineRule]

        init(rules: [any FollowUpBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpBaseline) -> [String] {
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

        func requireValid(_ item: FollowUpBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpBaseline]) -> [String: [String]] {
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

    static func defaultFollowUpBaselineValidator() -> FollowUpBaselineValidator {
        return FollowUpBaselineValidator(
            rules: [
                FollowUpBaselineAllowedTitleRule(allowed: []),
                FollowUpBaselineRequiredTitleRule(message: "follow up baseline needs this field"),
                FollowUpBaselineRequiredWardRule(message: "follow up baseline needs an entry"),
                FollowUpBaselineWardLengthRule(maxLength: 255),
                FollowUpBaselinePinnedGuardRule(limit: 86400),
                FollowUpBaselineRequiredCodeRule(message: "follow up baseline needs an entry"),
            ]
        )
    }
}

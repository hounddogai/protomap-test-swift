import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up group must pass. Check returns its problems, or none.
    protocol FollowUpGroupRule {
        func check(_ item: FollowUpGroup) -> [String]
    }

    final class FollowUpGroupWardLengthRule: FollowUpGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpGroup) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpGroupLimitRangeRule: FollowUpGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpGroup) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FollowUpGroupRequiredWardRule: FollowUpGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpGroup) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpGroupCodeLengthRule: FollowUpGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up group.
    final class FollowUpGroupValidator {
        var rules: [any FollowUpGroupRule]

        init(rules: [any FollowUpGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpGroup]) -> [String: [String]] {
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

    static func defaultFollowUpGroupValidator() -> FollowUpGroupValidator {
        return FollowUpGroupValidator(
            rules: [
                FollowUpGroupWardLengthRule(maxLength: 64),
                FollowUpGroupLimitRangeRule(min: 32, max: 86400),
                FollowUpGroupRequiredWardRule(message: "follow up group needs an entry"),
                FollowUpGroupCodeLengthRule(maxLength: 80),
            ]
        )
    }
}

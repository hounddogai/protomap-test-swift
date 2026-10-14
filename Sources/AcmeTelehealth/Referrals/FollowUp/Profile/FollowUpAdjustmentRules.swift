import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up adjustment must pass. Check returns its problems, or none.
    protocol FollowUpAdjustmentRule {
        func check(_ item: FollowUpAdjustment) -> [String]
    }

    final class FollowUpAdjustmentNameLengthRule: FollowUpAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpAdjustmentCodePrefixRule: FollowUpAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpAdjustmentLimitRangeRule: FollowUpAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpAdjustment) -> [String] {
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

    /// Runs every rule of a follow up adjustment.
    final class FollowUpAdjustmentValidator {
        var rules: [any FollowUpAdjustmentRule]

        init(rules: [any FollowUpAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpAdjustment]) -> [String: [String]] {
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

    static func defaultFollowUpAdjustmentValidator() -> FollowUpAdjustmentValidator {
        return FollowUpAdjustmentValidator(
            rules: [
                FollowUpAdjustmentNameLengthRule(maxLength: 32),
                FollowUpAdjustmentCodePrefixRule(prefix: "ACM"),
                FollowUpAdjustmentLimitRangeRule(min: 80, max: 120),
            ]
        )
    }
}

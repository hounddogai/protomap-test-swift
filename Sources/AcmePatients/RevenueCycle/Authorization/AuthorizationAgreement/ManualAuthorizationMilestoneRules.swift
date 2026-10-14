import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual authorization milestone must pass. Check returns its problems, or none.
    protocol ManualAuthorizationMilestoneRule {
        func check(_ item: ManualAuthorizationMilestone) -> [String]
    }

    final class ManualAuthorizationMilestoneAllowedCodeRule: ManualAuthorizationMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualAuthorizationMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class ManualAuthorizationMilestoneTitleLengthRule: ManualAuthorizationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAuthorizationMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAuthorizationMilestoneCodePrefixRule: ManualAuthorizationMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualAuthorizationMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualAuthorizationMilestoneUpdatedAtRangeRule: ManualAuthorizationMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAuthorizationMilestone) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual authorization milestone.
    final class ManualAuthorizationMilestoneValidator {
        var rules: [any ManualAuthorizationMilestoneRule]

        init(rules: [any ManualAuthorizationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAuthorizationMilestone) -> [String] {
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

        func requireValid(_ item: ManualAuthorizationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAuthorizationMilestone]) -> [String: [String]] {
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

    static func defaultManualAuthorizationMilestoneValidator() -> ManualAuthorizationMilestoneValidator {
        return ManualAuthorizationMilestoneValidator(
            rules: [
                ManualAuthorizationMilestoneAllowedCodeRule(allowed: ["primary", "manual"]),
                ManualAuthorizationMilestoneTitleLengthRule(maxLength: 80),
                ManualAuthorizationMilestoneCodePrefixRule(prefix: "ACM"),
                ManualAuthorizationMilestoneUpdatedAtRangeRule(min: 16, max: 86400),
            ]
        )
    }
}

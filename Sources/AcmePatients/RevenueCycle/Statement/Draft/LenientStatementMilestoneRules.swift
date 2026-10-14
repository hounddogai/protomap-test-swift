import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient statement milestone must pass. Check returns its problems, or none.
    protocol LenientStatementMilestoneRule {
        func check(_ item: LenientStatementMilestone) -> [String]
    }

    final class LenientStatementMilestoneLocaleLengthRule: LenientStatementMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientStatementMilestone) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientStatementMilestoneLabelLengthRule: LenientStatementMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientStatementMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientStatementMilestoneApprovedGuardRule: LenientStatementMilestoneRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientStatementMilestone) -> [String] {
            if item.approved && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient statement milestone.
    final class LenientStatementMilestoneValidator {
        var rules: [any LenientStatementMilestoneRule]

        init(rules: [any LenientStatementMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientStatementMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientStatementMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientStatementMilestone]) -> [String: [String]] {
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

    static func defaultLenientStatementMilestoneValidator() -> LenientStatementMilestoneValidator {
        return LenientStatementMilestoneValidator(
            rules: [
                LenientStatementMilestoneLocaleLengthRule(maxLength: 64),
                LenientStatementMilestoneLabelLengthRule(maxLength: 32),
                LenientStatementMilestoneApprovedGuardRule(limit: 255),
            ]
        )
    }
}

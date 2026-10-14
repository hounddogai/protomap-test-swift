import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network milestone must pass. Check returns its problems, or none.
    protocol ManualNetworkMilestoneRule {
        func check(_ item: ManualNetworkMilestone) -> [String]
    }

    final class ManualNetworkMilestoneSequenceRangeRule: ManualNetworkMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkMilestone) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualNetworkMilestoneCodeLengthRule: ManualNetworkMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkMilestoneEndsAtRangeRule: ManualNetworkMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkMilestone) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualNetworkMilestoneAllowedExternalRefRule: ManualNetworkMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualNetworkMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a manual network milestone.
    final class ManualNetworkMilestoneValidator {
        var rules: [any ManualNetworkMilestoneRule]

        init(rules: [any ManualNetworkMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkMilestone) -> [String] {
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

        func requireValid(_ item: ManualNetworkMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkMilestone]) -> [String: [String]] {
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

    static func defaultManualNetworkMilestoneValidator() -> ManualNetworkMilestoneValidator {
        return ManualNetworkMilestoneValidator(
            rules: [
                ManualNetworkMilestoneSequenceRangeRule(min: 16, max: 80),
                ManualNetworkMilestoneCodeLengthRule(maxLength: 120),
                ManualNetworkMilestoneEndsAtRangeRule(min: 80, max: 1000),
                ManualNetworkMilestoneAllowedExternalRefRule(allowed: ["strict", "lenient", "manual"]),
            ]
        )
    }
}

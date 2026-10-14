import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up allocation must pass. Check returns its problems, or none.
    protocol FollowUpAllocationRule {
        func check(_ item: FollowUpAllocation) -> [String]
    }

    final class FollowUpAllocationUnitLengthRule: FollowUpAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpAllocation) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpAllocationLabelLengthRule: FollowUpAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpAllocationRevisionRangeRule: FollowUpAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpAllocation) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpAllocationRequiredCodeRule: FollowUpAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpAllocationCodeLengthRule: FollowUpAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up allocation.
    final class FollowUpAllocationValidator {
        var rules: [any FollowUpAllocationRule]

        init(rules: [any FollowUpAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpAllocation]) -> [String: [String]] {
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

    static func defaultFollowUpAllocationValidator() -> FollowUpAllocationValidator {
        return FollowUpAllocationValidator(
            rules: [
                FollowUpAllocationUnitLengthRule(maxLength: 64),
                FollowUpAllocationLabelLengthRule(maxLength: 32),
                FollowUpAllocationRevisionRangeRule(min: 120, max: 86400),
                FollowUpAllocationRequiredCodeRule(message: "follow up allocation needs an entry"),
                FollowUpAllocationCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

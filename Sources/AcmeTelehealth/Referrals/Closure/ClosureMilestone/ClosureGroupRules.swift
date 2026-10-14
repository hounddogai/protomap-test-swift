import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure group must pass. Check returns its problems, or none.
    protocol ClosureGroupRule {
        func check(_ item: ClosureGroup) -> [String]
    }

    final class ClosureGroupRequiredFacilityRule: ClosureGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureGroup) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureGroupTitleLengthRule: ClosureGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureGroupCostRangeRule: ClosureGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureGroup) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClosureGroupRequiredTitleRule: ClosureGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure group.
    final class ClosureGroupValidator {
        var rules: [any ClosureGroupRule]

        init(rules: [any ClosureGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureGroup]) -> [String: [String]] {
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

    static func defaultClosureGroupValidator() -> ClosureGroupValidator {
        return ClosureGroupValidator(
            rules: [
                ClosureGroupRequiredFacilityRule(message: "closure group needs this field"),
                ClosureGroupTitleLengthRule(maxLength: 16),
                ClosureGroupCostRangeRule(min: 8.6, max: 4997.4),
                ClosureGroupRequiredTitleRule(message: "closure group needs this field"),
            ]
        )
    }
}

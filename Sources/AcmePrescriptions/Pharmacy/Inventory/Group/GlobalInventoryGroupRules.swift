import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global inventory group must pass. Check returns its problems, or none.
    protocol GlobalInventoryGroupRule {
        func check(_ item: GlobalInventoryGroup) -> [String]
    }

    final class GlobalInventoryGroupUpdatedAtRangeRule: GlobalInventoryGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalInventoryGroup) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalInventoryGroupCodeLengthRule: GlobalInventoryGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInventoryGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInventoryGroupVisitMinutesRangeRule: GlobalInventoryGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalInventoryGroup) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalInventoryGroupRequiredTitleRule: GlobalInventoryGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInventoryGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global inventory group.
    final class GlobalInventoryGroupValidator {
        var rules: [any GlobalInventoryGroupRule]

        init(rules: [any GlobalInventoryGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInventoryGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalInventoryGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInventoryGroup]) -> [String: [String]] {
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

    static func defaultGlobalInventoryGroupValidator() -> GlobalInventoryGroupValidator {
        return GlobalInventoryGroupValidator(
            rules: [
                GlobalInventoryGroupUpdatedAtRangeRule(min: 32, max: 1000),
                GlobalInventoryGroupCodeLengthRule(maxLength: 16),
                GlobalInventoryGroupVisitMinutesRangeRule(min: 64, max: 120),
                GlobalInventoryGroupRequiredTitleRule(message: "global inventory group needs this field"),
            ]
        )
    }
}

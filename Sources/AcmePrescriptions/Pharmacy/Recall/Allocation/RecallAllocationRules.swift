import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall allocation must pass. Check returns its problems, or none.
    protocol RecallAllocationRule {
        func check(_ item: RecallAllocation) -> [String]
    }

    final class RecallAllocationTitleLengthRule: RecallAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallAllocationRequiredTitleRule: RecallAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallAllocationVisitMinutesRangeRule: RecallAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallAllocation) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallAllocationCodeLengthRule: RecallAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallAllocationActiveGuardRule: RecallAllocationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RecallAllocation) -> [String] {
            if item.active && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a recall allocation.
    final class RecallAllocationValidator {
        var rules: [any RecallAllocationRule]

        init(rules: [any RecallAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallAllocation]) -> [String: [String]] {
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

    static func defaultRecallAllocationValidator() -> RecallAllocationValidator {
        return RecallAllocationValidator(
            rules: [
                RecallAllocationTitleLengthRule(maxLength: 64),
                RecallAllocationRequiredTitleRule(message: "recall allocation needs this field"),
                RecallAllocationVisitMinutesRangeRule(min: 86400, max: 86400),
                RecallAllocationCodeLengthRule(maxLength: 120),
                RecallAllocationActiveGuardRule(limit: 1000),
            ]
        )
    }
}

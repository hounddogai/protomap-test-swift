import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback statement assignment must pass. Check returns its problems, or none.
    protocol FallbackStatementAssignmentRule {
        func check(_ item: FallbackStatementAssignment) -> [String]
    }

    final class FallbackStatementAssignmentAmountRangeRule: FallbackStatementAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackStatementAssignment) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackStatementAssignmentRequiredDescriptionRule: FallbackStatementAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackStatementAssignment) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackStatementAssignmentWindowDaysRangeRule: FallbackStatementAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackStatementAssignment) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackStatementAssignmentTitleLengthRule: FallbackStatementAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackStatementAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackStatementAssignmentRequiredCodeRule: FallbackStatementAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackStatementAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback statement assignment.
    final class FallbackStatementAssignmentValidator {
        var rules: [any FallbackStatementAssignmentRule]

        init(rules: [any FallbackStatementAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackStatementAssignment) -> [String] {
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

        func requireValid(_ item: FallbackStatementAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackStatementAssignment]) -> [String: [String]] {
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

    static func defaultFallbackStatementAssignmentValidator() -> FallbackStatementAssignmentValidator {
        return FallbackStatementAssignmentValidator(
            rules: [
                FallbackStatementAssignmentAmountRangeRule(min: 0.3, max: 4701.3),
                FallbackStatementAssignmentRequiredDescriptionRule(
                    message: "fallback statement assignment needs a value"
                ),
                FallbackStatementAssignmentWindowDaysRangeRule(min: 32, max: 80),
                FallbackStatementAssignmentTitleLengthRule(maxLength: 255),
                FallbackStatementAssignmentRequiredCodeRule(message: "fallback statement assignment needs an entry"),
            ]
        )
    }
}

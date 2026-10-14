import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict language assignment must pass. Check returns its problems, or none.
    protocol StrictLanguageAssignmentRule {
        func check(_ item: StrictLanguageAssignment) -> [String]
    }

    final class StrictLanguageAssignmentRequiredCodeRule: StrictLanguageAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictLanguageAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictLanguageAssignmentTitleLengthRule: StrictLanguageAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictLanguageAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictLanguageAssignmentRequiredTitleRule: StrictLanguageAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictLanguageAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictLanguageAssignmentRequiredLocaleRule: StrictLanguageAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictLanguageAssignment) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictLanguageAssignmentRateRangeRule: StrictLanguageAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictLanguageAssignment) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictLanguageAssignmentVisitMinutesRangeRule: StrictLanguageAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictLanguageAssignment) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict language assignment.
    final class StrictLanguageAssignmentValidator {
        var rules: [any StrictLanguageAssignmentRule]

        init(rules: [any StrictLanguageAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictLanguageAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictLanguageAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictLanguageAssignment]) -> [String: [String]] {
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

    static func defaultStrictLanguageAssignmentValidator() -> StrictLanguageAssignmentValidator {
        return StrictLanguageAssignmentValidator(
            rules: [
                StrictLanguageAssignmentRequiredCodeRule(message: "strict language assignment needs this field"),
                StrictLanguageAssignmentTitleLengthRule(maxLength: 16),
                StrictLanguageAssignmentRequiredTitleRule(message: "strict language assignment needs a value"),
                StrictLanguageAssignmentRequiredLocaleRule(message: "strict language assignment needs this field"),
                StrictLanguageAssignmentRateRangeRule(min: 9.5, max: 1120.5),
                StrictLanguageAssignmentVisitMinutesRangeRule(min: 64, max: 80),
            ]
        )
    }
}

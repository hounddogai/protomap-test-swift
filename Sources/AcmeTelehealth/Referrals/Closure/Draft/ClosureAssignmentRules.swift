import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure assignment must pass. Check returns its problems, or none.
    protocol ClosureAssignmentRule {
        func check(_ item: ClosureAssignment) -> [String]
    }

    final class ClosureAssignmentRequiredTitleRule: ClosureAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureAssignmentRequiredCodeRule: ClosureAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureAssignmentCodeLengthRule: ClosureAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureAssignmentTitleLengthRule: ClosureAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureAssignmentScoreRangeRule: ClosureAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureAssignment) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure assignment.
    final class ClosureAssignmentValidator {
        var rules: [any ClosureAssignmentRule]

        init(rules: [any ClosureAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureAssignment]) -> [String: [String]] {
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

    static func defaultClosureAssignmentValidator() -> ClosureAssignmentValidator {
        return ClosureAssignmentValidator(
            rules: [
                ClosureAssignmentRequiredTitleRule(message: "closure assignment needs this field"),
                ClosureAssignmentRequiredCodeRule(message: "closure assignment needs an entry"),
                ClosureAssignmentCodeLengthRule(maxLength: 1000),
                ClosureAssignmentTitleLengthRule(maxLength: 255),
                ClosureAssignmentScoreRangeRule(min: 8.6, max: 3428.5),
            ]
        )
    }
}

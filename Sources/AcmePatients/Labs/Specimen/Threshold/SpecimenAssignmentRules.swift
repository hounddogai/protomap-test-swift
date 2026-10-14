import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen assignment must pass. Check returns its problems, or none.
    protocol SpecimenAssignmentRule {
        func check(_ item: SpecimenAssignment) -> [String]
    }

    final class SpecimenAssignmentTitleLengthRule: SpecimenAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenAssignmentCodeLengthRule: SpecimenAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenAssignmentAllowedContactEmailRule: SpecimenAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is unknown"]
            }
            return []
        }
    }

    final class SpecimenAssignmentAmountRangeRule: SpecimenAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenAssignment) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenAssignmentRequiredTitleRule: SpecimenAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenAssignmentRequiredLocaleRule: SpecimenAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenAssignment) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen assignment.
    final class SpecimenAssignmentValidator {
        var rules: [any SpecimenAssignmentRule]

        init(rules: [any SpecimenAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenAssignment]) -> [String: [String]] {
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

    static func defaultSpecimenAssignmentValidator() -> SpecimenAssignmentValidator {
        return SpecimenAssignmentValidator(
            rules: [
                SpecimenAssignmentTitleLengthRule(maxLength: 16),
                SpecimenAssignmentCodeLengthRule(maxLength: 16),
                SpecimenAssignmentAllowedContactEmailRule(allowed: ["capped"]),
                SpecimenAssignmentAmountRangeRule(min: 8.5, max: 2794.7),
                SpecimenAssignmentRequiredTitleRule(message: "specimen assignment needs this field"),
                SpecimenAssignmentRequiredLocaleRule(message: "specimen assignment needs an entry"),
            ]
        )
    }
}

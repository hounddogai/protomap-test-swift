import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment entry must pass. Check returns its problems, or none.
    protocol AssessmentEntryRule {
        func check(_ item: AssessmentEntry) -> [String]
    }

    final class AssessmentEntryEndsAtRangeRule: AssessmentEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentEntry) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentEntryWardLengthRule: AssessmentEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentEntry) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentEntryRequiredCodeRule: AssessmentEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentEntryCapacityRangeRule: AssessmentEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentEntry) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentEntryAllowedWardRule: AssessmentEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is expired"]
            }
            return []
        }
    }

    final class AssessmentEntryGraceDaysRangeRule: AssessmentEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentEntry) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a assessment entry.
    final class AssessmentEntryValidator {
        var rules: [any AssessmentEntryRule]

        init(rules: [any AssessmentEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentEntry]) -> [String: [String]] {
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

    static func defaultAssessmentEntryValidator() -> AssessmentEntryValidator {
        return AssessmentEntryValidator(
            rules: [
                AssessmentEntryEndsAtRangeRule(min: 16, max: 1000),
                AssessmentEntryWardLengthRule(maxLength: 32),
                AssessmentEntryRequiredCodeRule(message: "assessment entry needs this field"),
                AssessmentEntryCapacityRangeRule(min: 32, max: 1000),
                AssessmentEntryAllowedWardRule(allowed: ["strict"]),
                AssessmentEntryGraceDaysRangeRule(min: 32, max: 86400),
            ]
        )
    }
}

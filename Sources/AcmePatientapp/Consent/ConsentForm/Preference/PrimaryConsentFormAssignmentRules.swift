import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary consent form assignment must pass. Check returns its problems, or none.
    protocol PrimaryConsentFormAssignmentRule {
        func check(_ item: PrimaryConsentFormAssignment) -> [String]
    }

    final class PrimaryConsentFormAssignmentCountryLengthRule: PrimaryConsentFormAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryConsentFormAssignment) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryConsentFormAssignmentRequiredTimezoneRule: PrimaryConsentFormAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryConsentFormAssignment) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryConsentFormAssignmentTimezoneLengthRule: PrimaryConsentFormAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryConsentFormAssignment) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryConsentFormAssignmentPriorityRangeRule: PrimaryConsentFormAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryConsentFormAssignment) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryConsentFormAssignmentBudgetRangeRule: PrimaryConsentFormAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryConsentFormAssignment) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary consent form assignment.
    final class PrimaryConsentFormAssignmentValidator {
        var rules: [any PrimaryConsentFormAssignmentRule]

        init(rules: [any PrimaryConsentFormAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryConsentFormAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryConsentFormAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryConsentFormAssignment]) -> [String: [String]] {
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

    static func defaultPrimaryConsentFormAssignmentValidator() -> PrimaryConsentFormAssignmentValidator {
        return PrimaryConsentFormAssignmentValidator(
            rules: [
                PrimaryConsentFormAssignmentCountryLengthRule(maxLength: 16),
                PrimaryConsentFormAssignmentRequiredTimezoneRule(
                    message: "primary consent form assignment needs a value"
                ),
                PrimaryConsentFormAssignmentTimezoneLengthRule(maxLength: 3600),
                PrimaryConsentFormAssignmentPriorityRangeRule(min: 80, max: 1000),
                PrimaryConsentFormAssignmentBudgetRangeRule(min: 8.7, max: 92.0),
            ]
        )
    }
}

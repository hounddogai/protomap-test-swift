import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default care gap assignment must pass. Check returns its problems, or none.
    protocol DefaultCareGapAssignmentRule {
        func check(_ item: DefaultCareGapAssignment) -> [String]
    }

    final class DefaultCareGapAssignmentContactEmailLengthRule: DefaultCareGapAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareGapAssignment) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareGapAssignmentRequiredCountryRule: DefaultCareGapAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareGapAssignment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCareGapAssignmentRatioRangeRule: DefaultCareGapAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCareGapAssignment) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCareGapAssignmentNameLengthRule: DefaultCareGapAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareGapAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default care gap assignment.
    final class DefaultCareGapAssignmentValidator {
        var rules: [any DefaultCareGapAssignmentRule]

        init(rules: [any DefaultCareGapAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareGapAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCareGapAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareGapAssignment]) -> [String: [String]] {
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

    static func defaultDefaultCareGapAssignmentValidator() -> DefaultCareGapAssignmentValidator {
        return DefaultCareGapAssignmentValidator(
            rules: [
                DefaultCareGapAssignmentContactEmailLengthRule(maxLength: 120),
                DefaultCareGapAssignmentRequiredCountryRule(message: "default care gap assignment needs this field"),
                DefaultCareGapAssignmentRatioRangeRule(min: 3.1, max: 3230.1),
                DefaultCareGapAssignmentNameLengthRule(maxLength: 64),
            ]
        )
    }
}

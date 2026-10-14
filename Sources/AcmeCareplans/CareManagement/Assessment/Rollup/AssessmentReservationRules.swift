import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment reservation must pass. Check returns its problems, or none.
    protocol AssessmentReservationRule {
        func check(_ item: AssessmentReservation) -> [String]
    }

    final class AssessmentReservationLabelLengthRule: AssessmentReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentReservationMinimumRangeRule: AssessmentReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentReservation) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentReservationRequiredNameRule: AssessmentReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentReservationCodePrefixRule: AssessmentReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentReservationReviewerLengthRule: AssessmentReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentReservation) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment reservation.
    final class AssessmentReservationValidator {
        var rules: [any AssessmentReservationRule]

        init(rules: [any AssessmentReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentReservation) -> [String] {
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

        func requireValid(_ item: AssessmentReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentReservation]) -> [String: [String]] {
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

    static func defaultAssessmentReservationValidator() -> AssessmentReservationValidator {
        return AssessmentReservationValidator(
            rules: [
                AssessmentReservationLabelLengthRule(maxLength: 32),
                AssessmentReservationMinimumRangeRule(min: 5.1, max: 3566.4),
                AssessmentReservationRequiredNameRule(message: "assessment reservation needs this field"),
                AssessmentReservationCodePrefixRule(prefix: "ACM"),
                AssessmentReservationReviewerLengthRule(maxLength: 1000),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary review must pass. Check returns its problems, or none.
    protocol FormularyReviewRule {
        func check(_ item: FormularyReview) -> [String]
    }

    final class FormularyReviewProcedureCodeLengthRule: FormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyReview) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyReviewAmountRangeRule: FormularyReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyReview) -> [String] {
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

    final class FormularyReviewTimezoneLengthRule: FormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyReview) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyReviewRequiredLabelRule: FormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyReviewRequiredTimezoneRule: FormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyReview) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyReviewAcuityRangeRule: FormularyReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyReview) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary review.
    final class FormularyReviewValidator {
        var rules: [any FormularyReviewRule]

        init(rules: [any FormularyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyReview) -> [String] {
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

        func requireValid(_ item: FormularyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyReview]) -> [String: [String]] {
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

    static func defaultFormularyReviewValidator() -> FormularyReviewValidator {
        return FormularyReviewValidator(
            rules: [
                FormularyReviewProcedureCodeLengthRule(maxLength: 120),
                FormularyReviewAmountRangeRule(min: 6.8, max: 2180.9),
                FormularyReviewTimezoneLengthRule(maxLength: 32),
                FormularyReviewRequiredLabelRule(message: "formulary review needs a value"),
                FormularyReviewRequiredTimezoneRule(message: "formulary review needs a value"),
                FormularyReviewAcuityRangeRule(min: 16, max: 64),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary adjustment must pass. Check returns its problems, or none.
    protocol FormularyAdjustmentRule {
        func check(_ item: FormularyAdjustment) -> [String]
    }

    final class FormularyAdjustmentStartsAtRangeRule: FormularyAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyAdjustment) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyAdjustmentSpecialtyLengthRule: FormularyAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyAdjustment) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyAdjustmentLabelLengthRule: FormularyAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyAdjustmentRequiredCodeRule: FormularyAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyAdjustmentRequiredPayerRule: FormularyAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyAdjustment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyAdjustmentRequiredSpecialtyRule: FormularyAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyAdjustment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a formulary adjustment.
    final class FormularyAdjustmentValidator {
        var rules: [any FormularyAdjustmentRule]

        init(rules: [any FormularyAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyAdjustment]) -> [String: [String]] {
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

    static func defaultFormularyAdjustmentValidator() -> FormularyAdjustmentValidator {
        return FormularyAdjustmentValidator(
            rules: [
                FormularyAdjustmentStartsAtRangeRule(min: 16, max: 3600),
                FormularyAdjustmentSpecialtyLengthRule(maxLength: 86400),
                FormularyAdjustmentLabelLengthRule(maxLength: 80),
                FormularyAdjustmentRequiredCodeRule(message: "formulary adjustment needs this field"),
                FormularyAdjustmentRequiredPayerRule(message: "formulary adjustment needs this field"),
                FormularyAdjustmentRequiredSpecialtyRule(message: "formulary adjustment needs this field"),
            ]
        )
    }
}

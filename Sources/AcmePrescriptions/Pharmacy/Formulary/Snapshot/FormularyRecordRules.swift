import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary record must pass. Check returns its problems, or none.
    protocol FormularyRecordRule {
        func check(_ item: FormularyRecord) -> [String]
    }

    final class FormularyRecordExpiresAtRangeRule: FormularyRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyRecord) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyRecordRequiredAllergyRule: FormularyRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyRecord) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyRecordWeightRangeRule: FormularyRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyRecord) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a formulary record.
    final class FormularyRecordValidator {
        var rules: [any FormularyRecordRule]

        init(rules: [any FormularyRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyRecord]) -> [String: [String]] {
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

    static func defaultFormularyRecordValidator() -> FormularyRecordValidator {
        return FormularyRecordValidator(
            rules: [
                FormularyRecordExpiresAtRangeRule(min: 16, max: 32),
                FormularyRecordRequiredAllergyRule(message: "formulary record needs an entry"),
                FormularyRecordWeightRangeRule(min: 9.4, max: 1101.5),
            ]
        )
    }
}

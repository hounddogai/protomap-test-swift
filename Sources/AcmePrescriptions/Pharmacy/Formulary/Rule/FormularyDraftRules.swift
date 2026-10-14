import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary draft must pass. Check returns its problems, or none.
    protocol FormularyDraftRule {
        func check(_ item: FormularyDraft) -> [String]
    }

    final class FormularyDraftAcuityRangeRule: FormularyDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyDraft) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyDraftRequiredExternalRefRule: FormularyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyDraft) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyDraftCodeLengthRule: FormularyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyDraftScoreRangeRule: FormularyDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyDraft) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyDraftNameLengthRule: FormularyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyDraftRequiredTimezoneRule: FormularyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyDraft) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a formulary draft.
    final class FormularyDraftValidator {
        var rules: [any FormularyDraftRule]

        init(rules: [any FormularyDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyDraft]) -> [String: [String]] {
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

    static func defaultFormularyDraftValidator() -> FormularyDraftValidator {
        return FormularyDraftValidator(
            rules: [
                FormularyDraftAcuityRangeRule(min: 16, max: 64),
                FormularyDraftRequiredExternalRefRule(message: "formulary draft needs an entry"),
                FormularyDraftCodeLengthRule(maxLength: 16),
                FormularyDraftScoreRangeRule(min: 1.6, max: 4945.7),
                FormularyDraftNameLengthRule(maxLength: 255),
                FormularyDraftRequiredTimezoneRule(message: "formulary draft needs a value"),
            ]
        )
    }
}

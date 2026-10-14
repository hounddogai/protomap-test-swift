import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary batch must pass. Check returns its problems, or none.
    protocol FormularyBatchRule {
        func check(_ item: FormularyBatch) -> [String]
    }

    final class FormularyBatchAllowedCodeRule: FormularyBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FormularyBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class FormularyBatchRequiredLocaleRule: FormularyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyBatch) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyBatchRequiredTitleRule: FormularyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyBatchDosageMgRangeRule: FormularyBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyBatch) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyBatchCodeLengthRule: FormularyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyBatchTitleLengthRule: FormularyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary batch.
    final class FormularyBatchValidator {
        var rules: [any FormularyBatchRule]

        init(rules: [any FormularyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyBatch) -> [String] {
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

        func requireValid(_ item: FormularyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyBatch]) -> [String: [String]] {
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

    static func defaultFormularyBatchValidator() -> FormularyBatchValidator {
        return FormularyBatchValidator(
            rules: [
                FormularyBatchAllowedCodeRule(allowed: ["rolling"]),
                FormularyBatchRequiredLocaleRule(message: "formulary batch needs a value"),
                FormularyBatchRequiredTitleRule(message: "formulary batch needs this field"),
                FormularyBatchDosageMgRangeRule(min: 3.2, max: 3976.7),
                FormularyBatchCodeLengthRule(maxLength: 3600),
                FormularyBatchTitleLengthRule(maxLength: 255),
            ]
        )
    }
}

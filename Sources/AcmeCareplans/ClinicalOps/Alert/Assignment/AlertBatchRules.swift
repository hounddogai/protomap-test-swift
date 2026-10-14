import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert batch must pass. Check returns its problems, or none.
    protocol AlertBatchRule {
        func check(_ item: AlertBatch) -> [String]
    }

    final class AlertBatchCodePrefixRule: AlertBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertBatchRequiredDescriptionRule: AlertBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertBatch) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertBatchRequiredLocaleRule: AlertBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertBatch) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertBatchRevisionRangeRule: AlertBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertBatch) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertBatchRequiredCodeRule: AlertBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertBatchNameLengthRule: AlertBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert batch.
    final class AlertBatchValidator {
        var rules: [any AlertBatchRule]

        init(rules: [any AlertBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertBatch]) -> [String: [String]] {
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

    static func defaultAlertBatchValidator() -> AlertBatchValidator {
        return AlertBatchValidator(
            rules: [
                AlertBatchCodePrefixRule(prefix: "X"),
                AlertBatchRequiredDescriptionRule(message: "alert batch needs a value"),
                AlertBatchRequiredLocaleRule(message: "alert batch needs an entry"),
                AlertBatchRevisionRangeRule(min: 16, max: 32),
                AlertBatchRequiredCodeRule(message: "alert batch needs a value"),
                AlertBatchNameLengthRule(maxLength: 86400),
            ]
        )
    }
}

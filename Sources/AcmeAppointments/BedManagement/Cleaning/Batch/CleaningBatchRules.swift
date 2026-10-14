import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning batch must pass. Check returns its problems, or none.
    protocol CleaningBatchRule {
        func check(_ item: CleaningBatch) -> [String]
    }

    final class CleaningBatchRequiredCodeRule: CleaningBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningBatchAllowedUnitRule: CleaningBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is unknown"]
            }
            return []
        }
    }

    final class CleaningBatchRequiredLabelRule: CleaningBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningBatchLocaleLengthRule: CleaningBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningBatch) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningBatchRequiredLocaleRule: CleaningBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBatch) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning batch.
    final class CleaningBatchValidator {
        var rules: [any CleaningBatchRule]

        init(rules: [any CleaningBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningBatch]) -> [String: [String]] {
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

    static func defaultCleaningBatchValidator() -> CleaningBatchValidator {
        return CleaningBatchValidator(
            rules: [
                CleaningBatchRequiredCodeRule(message: "cleaning batch needs a value"),
                CleaningBatchAllowedUnitRule(allowed: []),
                CleaningBatchRequiredLabelRule(message: "cleaning batch needs an entry"),
                CleaningBatchLocaleLengthRule(maxLength: 120),
                CleaningBatchRequiredLocaleRule(message: "cleaning batch needs a value"),
            ]
        )
    }
}

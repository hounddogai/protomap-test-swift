import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement batch must pass. Check returns its problems, or none.
    protocol StatementBatchRule {
        func check(_ item: StatementBatch) -> [String]
    }

    final class StatementBatchCodeLengthRule: StatementBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementBatchRequiredTitleRule: StatementBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementBatchRequiredWardRule: StatementBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementBatch) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementBatchAllowedLabelRule: StatementBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    final class StatementBatchRequiredLabelRule: StatementBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement batch.
    final class StatementBatchValidator {
        var rules: [any StatementBatchRule]

        init(rules: [any StatementBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementBatch) -> [String] {
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

        func requireValid(_ item: StatementBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementBatch]) -> [String: [String]] {
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

    static func defaultStatementBatchValidator() -> StatementBatchValidator {
        return StatementBatchValidator(
            rules: [
                StatementBatchCodeLengthRule(maxLength: 255),
                StatementBatchRequiredTitleRule(message: "statement batch needs a value"),
                StatementBatchRequiredWardRule(message: "statement batch needs this field"),
                StatementBatchAllowedLabelRule(allowed: ["global"]),
                StatementBatchRequiredLabelRule(message: "statement batch needs an entry"),
            ]
        )
    }
}

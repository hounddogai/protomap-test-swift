import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default inventory batch must pass. Check returns its problems, or none.
    protocol DefaultInventoryBatchRule {
        func check(_ item: DefaultInventoryBatch) -> [String]
    }

    final class DefaultInventoryBatchRequiredNameRule: DefaultInventoryBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInventoryBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultInventoryBatchRequiredTitleRule: DefaultInventoryBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInventoryBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultInventoryBatchRequiredCodeRule: DefaultInventoryBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInventoryBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultInventoryBatchTitleLengthRule: DefaultInventoryBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInventoryBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultInventoryBatchRequiredProcedureCodeRule: DefaultInventoryBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInventoryBatch) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultInventoryBatchCodeLengthRule: DefaultInventoryBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInventoryBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default inventory batch.
    final class DefaultInventoryBatchValidator {
        var rules: [any DefaultInventoryBatchRule]

        init(rules: [any DefaultInventoryBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultInventoryBatch) -> [String] {
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

        func requireValid(_ item: DefaultInventoryBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultInventoryBatch]) -> [String: [String]] {
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

    static func defaultDefaultInventoryBatchValidator() -> DefaultInventoryBatchValidator {
        return DefaultInventoryBatchValidator(
            rules: [
                DefaultInventoryBatchRequiredNameRule(message: "default inventory batch needs a value"),
                DefaultInventoryBatchRequiredTitleRule(message: "default inventory batch needs a value"),
                DefaultInventoryBatchRequiredCodeRule(message: "default inventory batch needs this field"),
                DefaultInventoryBatchTitleLengthRule(maxLength: 86400),
                DefaultInventoryBatchRequiredProcedureCodeRule(message: "default inventory batch needs this field"),
                DefaultInventoryBatchCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}

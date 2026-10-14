import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched order set exception must pass. Check returns its problems, or none.
    protocol BatchedOrderSetExceptionRule {
        func check(_ item: BatchedOrderSetException) -> [String]
    }

    final class BatchedOrderSetExceptionVersionRangeRule: BatchedOrderSetExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOrderSetException) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedOrderSetExceptionCategoryLengthRule: BatchedOrderSetExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOrderSetException) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOrderSetExceptionRequiredCategoryRule: BatchedOrderSetExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOrderSetException) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOrderSetExceptionRequiredNameRule: BatchedOrderSetExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOrderSetException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOrderSetExceptionNameLengthRule: BatchedOrderSetExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOrderSetException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched order set exception.
    final class BatchedOrderSetExceptionValidator {
        var rules: [any BatchedOrderSetExceptionRule]

        init(rules: [any BatchedOrderSetExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOrderSetException) -> [String] {
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

        func requireValid(_ item: BatchedOrderSetException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOrderSetException]) -> [String: [String]] {
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

    static func defaultBatchedOrderSetExceptionValidator() -> BatchedOrderSetExceptionValidator {
        return BatchedOrderSetExceptionValidator(
            rules: [
                BatchedOrderSetExceptionVersionRangeRule(min: 120, max: 86400),
                BatchedOrderSetExceptionCategoryLengthRule(maxLength: 1000),
                BatchedOrderSetExceptionRequiredCategoryRule(message: "batched order set exception needs this field"),
                BatchedOrderSetExceptionRequiredNameRule(message: "batched order set exception needs a value"),
                BatchedOrderSetExceptionNameLengthRule(maxLength: 120),
            ]
        )
    }
}

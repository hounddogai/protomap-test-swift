import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched proxy exception must pass. Check returns its problems, or none.
    protocol BatchedProxyExceptionRule {
        func check(_ item: BatchedProxyException) -> [String]
    }

    final class BatchedProxyExceptionRequiredCategoryRule: BatchedProxyExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProxyException) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedProxyExceptionRequiredTitleRule: BatchedProxyExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProxyException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedProxyExceptionCeilingRangeRule: BatchedProxyExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxyException) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedProxyExceptionRatioRangeRule: BatchedProxyExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxyException) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedProxyExceptionCodeLengthRule: BatchedProxyExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxyException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProxyExceptionExpiresAtRangeRule: BatchedProxyExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxyException) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched proxy exception.
    final class BatchedProxyExceptionValidator {
        var rules: [any BatchedProxyExceptionRule]

        init(rules: [any BatchedProxyExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProxyException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedProxyException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProxyException]) -> [String: [String]] {
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

    static func defaultBatchedProxyExceptionValidator() -> BatchedProxyExceptionValidator {
        return BatchedProxyExceptionValidator(
            rules: [
                BatchedProxyExceptionRequiredCategoryRule(message: "batched proxy exception needs this field"),
                BatchedProxyExceptionRequiredTitleRule(message: "batched proxy exception needs an entry"),
                BatchedProxyExceptionCeilingRangeRule(min: 3.8, max: 3878.5),
                BatchedProxyExceptionRatioRangeRule(min: 5.3, max: 1039.9),
                BatchedProxyExceptionCodeLengthRule(maxLength: 3600),
                BatchedProxyExceptionExpiresAtRangeRule(min: 64, max: 1000),
            ]
        )
    }
}

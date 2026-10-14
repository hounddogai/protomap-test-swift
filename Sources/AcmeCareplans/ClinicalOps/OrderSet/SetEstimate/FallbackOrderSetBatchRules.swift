import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback order set batch must pass. Check returns its problems, or none.
    protocol FallbackOrderSetBatchRule {
        func check(_ item: FallbackOrderSetBatch) -> [String]
    }

    final class FallbackOrderSetBatchAmountRangeRule: FallbackOrderSetBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackOrderSetBatch) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackOrderSetBatchRequiredCodeRule: FallbackOrderSetBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOrderSetBatchCodePrefixRule: FallbackOrderSetBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackOrderSetBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackOrderSetBatchRequiredLabelRule: FallbackOrderSetBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOrderSetBatchCodeLengthRule: FallbackOrderSetBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOrderSetBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback order set batch.
    final class FallbackOrderSetBatchValidator {
        var rules: [any FallbackOrderSetBatchRule]

        init(rules: [any FallbackOrderSetBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOrderSetBatch) -> [String] {
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

        func requireValid(_ item: FallbackOrderSetBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOrderSetBatch]) -> [String: [String]] {
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

    static func defaultFallbackOrderSetBatchValidator() -> FallbackOrderSetBatchValidator {
        return FallbackOrderSetBatchValidator(
            rules: [
                FallbackOrderSetBatchAmountRangeRule(min: 0.2, max: 3448.2),
                FallbackOrderSetBatchRequiredCodeRule(message: "fallback order set batch needs this field"),
                FallbackOrderSetBatchCodePrefixRule(prefix: "ACM"),
                FallbackOrderSetBatchRequiredLabelRule(message: "fallback order set batch needs this field"),
                FallbackOrderSetBatchCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

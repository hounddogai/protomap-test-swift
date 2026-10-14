import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction batch must pass. Check returns its problems, or none.
    protocol InteractionBatchRule {
        func check(_ item: InteractionBatch) -> [String]
    }

    final class InteractionBatchCodePrefixRule: InteractionBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionBatchWardLengthRule: InteractionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionBatch) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionBatchSummaryLengthRule: InteractionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionBatch) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionBatchRequiredSummaryRule: InteractionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionBatch) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionBatchDosageMgRangeRule: InteractionBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionBatch) -> [String] {
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

    final class InteractionBatchCodeLengthRule: InteractionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction batch.
    final class InteractionBatchValidator {
        var rules: [any InteractionBatchRule]

        init(rules: [any InteractionBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionBatch) -> [String] {
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

        func requireValid(_ item: InteractionBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionBatch]) -> [String: [String]] {
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

    static func defaultInteractionBatchValidator() -> InteractionBatchValidator {
        return InteractionBatchValidator(
            rules: [
                InteractionBatchCodePrefixRule(prefix: "REF"),
                InteractionBatchWardLengthRule(maxLength: 1000),
                InteractionBatchSummaryLengthRule(maxLength: 16),
                InteractionBatchRequiredSummaryRule(message: "interaction batch needs a value"),
                InteractionBatchDosageMgRangeRule(min: 8.8, max: 3468.0),
                InteractionBatchCodeLengthRule(maxLength: 80),
            ]
        )
    }
}

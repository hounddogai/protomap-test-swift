import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched dispense policy must pass. Check returns its problems, or none.
    protocol BatchedDispensePolicyRule {
        func check(_ item: BatchedDispensePolicy) -> [String]
    }

    final class BatchedDispensePolicyRequiredCodeRule: BatchedDispensePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDispensePolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDispensePolicyCodePrefixRule: BatchedDispensePolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedDispensePolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedDispensePolicyCostRangeRule: BatchedDispensePolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDispensePolicy) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedDispensePolicyCodeLengthRule: BatchedDispensePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDispensePolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDispensePolicyBedLengthRule: BatchedDispensePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDispensePolicy) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDispensePolicyRequiredReviewerRule: BatchedDispensePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDispensePolicy) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched dispense policy.
    final class BatchedDispensePolicyValidator {
        var rules: [any BatchedDispensePolicyRule]

        init(rules: [any BatchedDispensePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDispensePolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDispensePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDispensePolicy]) -> [String: [String]] {
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

    static func defaultBatchedDispensePolicyValidator() -> BatchedDispensePolicyValidator {
        return BatchedDispensePolicyValidator(
            rules: [
                BatchedDispensePolicyRequiredCodeRule(message: "batched dispense policy needs an entry"),
                BatchedDispensePolicyCodePrefixRule(prefix: "ACM"),
                BatchedDispensePolicyCostRangeRule(min: 5.7, max: 2935.9),
                BatchedDispensePolicyCodeLengthRule(maxLength: 120),
                BatchedDispensePolicyBedLengthRule(maxLength: 120),
                BatchedDispensePolicyRequiredReviewerRule(message: "batched dispense policy needs this field"),
            ]
        )
    }
}

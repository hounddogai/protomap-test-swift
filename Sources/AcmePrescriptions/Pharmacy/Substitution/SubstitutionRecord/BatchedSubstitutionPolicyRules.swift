import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched substitution policy must pass. Check returns its problems, or none.
    protocol BatchedSubstitutionPolicyRule {
        func check(_ item: BatchedSubstitutionPolicy) -> [String]
    }

    final class BatchedSubstitutionPolicyGraceDaysRangeRule: BatchedSubstitutionPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSubstitutionPolicy) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSubstitutionPolicyRequiredCodeRule: BatchedSubstitutionPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSubstitutionPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSubstitutionPolicyCodePrefixRule: BatchedSubstitutionPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedSubstitutionPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedSubstitutionPolicyCodeLengthRule: BatchedSubstitutionPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSubstitutionPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSubstitutionPolicyCountryLengthRule: BatchedSubstitutionPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSubstitutionPolicy) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSubstitutionPolicyScoreRangeRule: BatchedSubstitutionPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSubstitutionPolicy) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched substitution policy.
    final class BatchedSubstitutionPolicyValidator {
        var rules: [any BatchedSubstitutionPolicyRule]

        init(rules: [any BatchedSubstitutionPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSubstitutionPolicy) -> [String] {
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

        func requireValid(_ item: BatchedSubstitutionPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSubstitutionPolicy]) -> [String: [String]] {
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

    static func defaultBatchedSubstitutionPolicyValidator() -> BatchedSubstitutionPolicyValidator {
        return BatchedSubstitutionPolicyValidator(
            rules: [
                BatchedSubstitutionPolicyGraceDaysRangeRule(min: 16, max: 120),
                BatchedSubstitutionPolicyRequiredCodeRule(message: "batched substitution policy needs this field"),
                BatchedSubstitutionPolicyCodePrefixRule(prefix: "Q"),
                BatchedSubstitutionPolicyCodeLengthRule(maxLength: 255),
                BatchedSubstitutionPolicyCountryLengthRule(maxLength: 32),
                BatchedSubstitutionPolicyScoreRangeRule(min: 7.6, max: 1259.8),
            ]
        )
    }
}

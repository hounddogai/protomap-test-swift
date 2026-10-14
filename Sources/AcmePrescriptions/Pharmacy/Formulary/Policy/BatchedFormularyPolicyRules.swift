import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched formulary policy must pass. Check returns its problems, or none.
    protocol BatchedFormularyPolicyRule {
        func check(_ item: BatchedFormularyPolicy) -> [String]
    }

    final class BatchedFormularyPolicyRequiredWardRule: BatchedFormularyPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedFormularyPolicy) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedFormularyPolicyCodePrefixRule: BatchedFormularyPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedFormularyPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedFormularyPolicyRequiredCountryRule: BatchedFormularyPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedFormularyPolicy) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedFormularyPolicyGraceDaysRangeRule: BatchedFormularyPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedFormularyPolicy) -> [String] {
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

    final class BatchedFormularyPolicyAllowedCountryRule: BatchedFormularyPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedFormularyPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is blocked"]
            }
            return []
        }
    }

    final class BatchedFormularyPolicyCountryLengthRule: BatchedFormularyPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedFormularyPolicy) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched formulary policy.
    final class BatchedFormularyPolicyValidator {
        var rules: [any BatchedFormularyPolicyRule]

        init(rules: [any BatchedFormularyPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedFormularyPolicy) -> [String] {
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

        func requireValid(_ item: BatchedFormularyPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedFormularyPolicy]) -> [String: [String]] {
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

    static func defaultBatchedFormularyPolicyValidator() -> BatchedFormularyPolicyValidator {
        return BatchedFormularyPolicyValidator(
            rules: [
                BatchedFormularyPolicyRequiredWardRule(message: "batched formulary policy needs a value"),
                BatchedFormularyPolicyCodePrefixRule(prefix: "ACM"),
                BatchedFormularyPolicyRequiredCountryRule(message: "batched formulary policy needs this field"),
                BatchedFormularyPolicyGraceDaysRangeRule(min: 64, max: 80),
                BatchedFormularyPolicyAllowedCountryRule(allowed: ["scheduled"]),
                BatchedFormularyPolicyCountryLengthRule(maxLength: 1000),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered credential policy must pass. Check returns its problems, or none.
    protocol TieredCredentialPolicyRule {
        func check(_ item: TieredCredentialPolicy) -> [String]
    }

    final class TieredCredentialPolicyRequiredCodeRule: TieredCredentialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCredentialPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCredentialPolicyMaximumRangeRule: TieredCredentialPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCredentialPolicy) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredCredentialPolicySummaryLengthRule: TieredCredentialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCredentialPolicy) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCredentialPolicyRequiredContactEmailRule: TieredCredentialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCredentialPolicy) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCredentialPolicyWindowDaysRangeRule: TieredCredentialPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCredentialPolicy) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredCredentialPolicyCodePrefixRule: TieredCredentialPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredCredentialPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered credential policy.
    final class TieredCredentialPolicyValidator {
        var rules: [any TieredCredentialPolicyRule]

        init(rules: [any TieredCredentialPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCredentialPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCredentialPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCredentialPolicy]) -> [String: [String]] {
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

    static func defaultTieredCredentialPolicyValidator() -> TieredCredentialPolicyValidator {
        return TieredCredentialPolicyValidator(
            rules: [
                TieredCredentialPolicyRequiredCodeRule(message: "tiered credential policy needs an entry"),
                TieredCredentialPolicyMaximumRangeRule(min: 3.3, max: 4688.0),
                TieredCredentialPolicySummaryLengthRule(maxLength: 1000),
                TieredCredentialPolicyRequiredContactEmailRule(message: "tiered credential policy needs an entry"),
                TieredCredentialPolicyWindowDaysRangeRule(min: 16, max: 1000),
                TieredCredentialPolicyCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

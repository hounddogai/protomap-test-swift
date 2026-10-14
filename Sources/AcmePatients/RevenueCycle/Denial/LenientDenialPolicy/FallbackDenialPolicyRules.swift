import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback denial policy must pass. Check returns its problems, or none.
    protocol FallbackDenialPolicyRule {
        func check(_ item: FallbackDenialPolicy) -> [String]
    }

    final class FallbackDenialPolicyRequiredCodeRule: FallbackDenialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDenialPolicyRequiredUnitRule: FallbackDenialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialPolicy) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDenialPolicyCodePrefixRule: FallbackDenialPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackDenialPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackDenialPolicySourceLengthRule: FallbackDenialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDenialPolicy) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback denial policy.
    final class FallbackDenialPolicyValidator {
        var rules: [any FallbackDenialPolicyRule]

        init(rules: [any FallbackDenialPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDenialPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackDenialPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDenialPolicy]) -> [String: [String]] {
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

    static func defaultFallbackDenialPolicyValidator() -> FallbackDenialPolicyValidator {
        return FallbackDenialPolicyValidator(
            rules: [
                FallbackDenialPolicyRequiredCodeRule(message: "fallback denial policy needs an entry"),
                FallbackDenialPolicyRequiredUnitRule(message: "fallback denial policy needs this field"),
                FallbackDenialPolicyCodePrefixRule(prefix: "X"),
                FallbackDenialPolicySourceLengthRule(maxLength: 32),
            ]
        )
    }
}

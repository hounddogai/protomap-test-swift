import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive shift policy must pass. Check returns its problems, or none.
    protocol AdaptiveShiftPolicyRule {
        func check(_ item: AdaptiveShiftPolicy) -> [String]
    }

    final class AdaptiveShiftPolicyExpiresAtRangeRule: AdaptiveShiftPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveShiftPolicy) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveShiftPolicyCodePrefixRule: AdaptiveShiftPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveShiftPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveShiftPolicyRequiredCodeRule: AdaptiveShiftPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveShiftPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveShiftPolicyCodeLengthRule: AdaptiveShiftPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveShiftPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive shift policy.
    final class AdaptiveShiftPolicyValidator {
        var rules: [any AdaptiveShiftPolicyRule]

        init(rules: [any AdaptiveShiftPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveShiftPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveShiftPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveShiftPolicy]) -> [String: [String]] {
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

    static func defaultAdaptiveShiftPolicyValidator() -> AdaptiveShiftPolicyValidator {
        return AdaptiveShiftPolicyValidator(
            rules: [
                AdaptiveShiftPolicyExpiresAtRangeRule(min: 16, max: 16),
                AdaptiveShiftPolicyCodePrefixRule(prefix: "ACM"),
                AdaptiveShiftPolicyRequiredCodeRule(message: "adaptive shift policy needs a value"),
                AdaptiveShiftPolicyCodeLengthRule(maxLength: 64),
            ]
        )
    }
}

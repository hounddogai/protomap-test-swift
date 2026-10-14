import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending denial policy must pass. Check returns its problems, or none.
    protocol PendingDenialPolicyRule {
        func check(_ item: PendingDenialPolicy) -> [String]
    }

    final class PendingDenialPolicyGraceDaysRangeRule: PendingDenialPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDenialPolicy) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingDenialPolicyAllowedCurrencyRule: PendingDenialPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingDenialPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is above maximum"]
            }
            return []
        }
    }

    final class PendingDenialPolicyCodeLengthRule: PendingDenialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDenialPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending denial policy.
    final class PendingDenialPolicyValidator {
        var rules: [any PendingDenialPolicyRule]

        init(rules: [any PendingDenialPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDenialPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingDenialPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDenialPolicy]) -> [String: [String]] {
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

    static func defaultPendingDenialPolicyValidator() -> PendingDenialPolicyValidator {
        return PendingDenialPolicyValidator(
            rules: [
                PendingDenialPolicyGraceDaysRangeRule(min: 1000, max: 3600),
                PendingDenialPolicyAllowedCurrencyRule(allowed: []),
                PendingDenialPolicyCodeLengthRule(maxLength: 120),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global credential tier must pass. Check returns its problems, or none.
    protocol GlobalCredentialTierRule {
        func check(_ item: GlobalCredentialTier) -> [String]
    }

    final class GlobalCredentialTierDiscountRangeRule: GlobalCredentialTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCredentialTier) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCredentialTierActiveGuardRule: GlobalCredentialTierRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalCredentialTier) -> [String] {
            if item.active && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class GlobalCredentialTierAllowedLabelRule: GlobalCredentialTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalCredentialTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class GlobalCredentialTierRequiredLabelRule: GlobalCredentialTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCredentialTierCodePrefixRule: GlobalCredentialTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCredentialTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCredentialTierLabelLengthRule: GlobalCredentialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCredentialTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global credential tier.
    final class GlobalCredentialTierValidator {
        var rules: [any GlobalCredentialTierRule]

        init(rules: [any GlobalCredentialTierRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCredentialTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCredentialTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCredentialTier]) -> [String: [String]] {
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

    static func defaultGlobalCredentialTierValidator() -> GlobalCredentialTierValidator {
        return GlobalCredentialTierValidator(
            rules: [
                GlobalCredentialTierDiscountRangeRule(min: 9.0, max: 2554.9),
                GlobalCredentialTierActiveGuardRule(limit: 3.6),
                GlobalCredentialTierAllowedLabelRule(allowed: []),
                GlobalCredentialTierRequiredLabelRule(message: "global credential tier needs this field"),
                GlobalCredentialTierCodePrefixRule(prefix: "ACM"),
                GlobalCredentialTierLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}

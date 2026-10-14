import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling claim window must pass. Check returns its problems, or none.
    protocol RollingClaimWindowRule {
        func check(_ item: RollingClaimWindow) -> [String]
    }

    final class RollingClaimWindowLabelLengthRule: RollingClaimWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingClaimWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingClaimWindowRequiredLabelRule: RollingClaimWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClaimWindowCeilingRangeRule: RollingClaimWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClaimWindow) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingClaimWindowCodePrefixRule: RollingClaimWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingClaimWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingClaimWindowRequiredCodeRule: RollingClaimWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClaimWindowAllowedCodeRule: RollingClaimWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingClaimWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling claim window.
    final class RollingClaimWindowValidator {
        var rules: [any RollingClaimWindowRule]

        init(rules: [any RollingClaimWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingClaimWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingClaimWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingClaimWindow]) -> [String: [String]] {
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

    static func defaultRollingClaimWindowValidator() -> RollingClaimWindowValidator {
        return RollingClaimWindowValidator(
            rules: [
                RollingClaimWindowLabelLengthRule(maxLength: 80),
                RollingClaimWindowRequiredLabelRule(message: "rolling claim window needs an entry"),
                RollingClaimWindowCeilingRangeRule(min: 6.4, max: 1966.1),
                RollingClaimWindowCodePrefixRule(prefix: "ACM"),
                RollingClaimWindowRequiredCodeRule(message: "rolling claim window needs a value"),
                RollingClaimWindowAllowedCodeRule(allowed: []),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling care protocol override must pass. Check returns its problems, or none.
    protocol RollingCareProtocolOverrideRule {
        func check(_ item: RollingCareProtocolOverride) -> [String]
    }

    final class RollingCareProtocolOverrideCountryLengthRule: RollingCareProtocolOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolOverride) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolOverrideRequiredCountryRule: RollingCareProtocolOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareProtocolOverride) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCareProtocolOverrideRequiredCodeRule: RollingCareProtocolOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareProtocolOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCareProtocolOverrideCodePrefixRule: RollingCareProtocolOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingCareProtocolOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingCareProtocolOverrideCodeLengthRule: RollingCareProtocolOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolOverrideBudgetRangeRule: RollingCareProtocolOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolOverride) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling care protocol override.
    final class RollingCareProtocolOverrideValidator {
        var rules: [any RollingCareProtocolOverrideRule]

        init(rules: [any RollingCareProtocolOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareProtocolOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCareProtocolOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareProtocolOverride]) -> [String: [String]] {
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

    static func defaultRollingCareProtocolOverrideValidator() -> RollingCareProtocolOverrideValidator {
        return RollingCareProtocolOverrideValidator(
            rules: [
                RollingCareProtocolOverrideCountryLengthRule(maxLength: 80),
                RollingCareProtocolOverrideRequiredCountryRule(
                    message: "rolling care protocol override needs an entry"
                ),
                RollingCareProtocolOverrideRequiredCodeRule(
                    message: "rolling care protocol override needs this field"
                ),
                RollingCareProtocolOverrideCodePrefixRule(prefix: "ACM"),
                RollingCareProtocolOverrideCodeLengthRule(maxLength: 80),
                RollingCareProtocolOverrideBudgetRangeRule(min: 4.4, max: 4899.5),
            ]
        )
    }
}

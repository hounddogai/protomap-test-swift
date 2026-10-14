import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default outreach override must pass. Check returns its problems, or none.
    protocol DefaultOutreachOverrideRule {
        func check(_ item: DefaultOutreachOverride) -> [String]
    }

    final class DefaultOutreachOverrideAllowedTimezoneRule: DefaultOutreachOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultOutreachOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is too long"]
            }
            return []
        }
    }

    final class DefaultOutreachOverrideRequiredNameRule: DefaultOutreachOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOutreachOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultOutreachOverrideRequiredCodeRule: DefaultOutreachOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOutreachOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultOutreachOverrideCodeLengthRule: DefaultOutreachOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultOutreachOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultOutreachOverrideBatchSizeRangeRule: DefaultOutreachOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultOutreachOverride) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultOutreachOverrideNameLengthRule: DefaultOutreachOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultOutreachOverride) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default outreach override.
    final class DefaultOutreachOverrideValidator {
        var rules: [any DefaultOutreachOverrideRule]

        init(rules: [any DefaultOutreachOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultOutreachOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultOutreachOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultOutreachOverride]) -> [String: [String]] {
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

    static func defaultDefaultOutreachOverrideValidator() -> DefaultOutreachOverrideValidator {
        return DefaultOutreachOverrideValidator(
            rules: [
                DefaultOutreachOverrideAllowedTimezoneRule(allowed: ["lenient", "manual"]),
                DefaultOutreachOverrideRequiredNameRule(message: "default outreach override needs an entry"),
                DefaultOutreachOverrideRequiredCodeRule(message: "default outreach override needs an entry"),
                DefaultOutreachOverrideCodeLengthRule(maxLength: 32),
                DefaultOutreachOverrideBatchSizeRangeRule(min: 80, max: 86400),
                DefaultOutreachOverrideNameLengthRule(maxLength: 86400),
            ]
        )
    }
}

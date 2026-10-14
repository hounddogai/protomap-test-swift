import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default program override must pass. Check returns its problems, or none.
    protocol DefaultProgramOverrideRule {
        func check(_ item: DefaultProgramOverride) -> [String]
    }

    final class DefaultProgramOverrideEndsAtRangeRule: DefaultProgramOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultProgramOverride) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultProgramOverrideRequiredTimezoneRule: DefaultProgramOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultProgramOverride) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultProgramOverrideLabelLengthRule: DefaultProgramOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultProgramOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultProgramOverrideRequiredCodeRule: DefaultProgramOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultProgramOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultProgramOverrideProcedureCodeLengthRule: DefaultProgramOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultProgramOverride) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultProgramOverrideAllowedProcedureCodeRule: DefaultProgramOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultProgramOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a default program override.
    final class DefaultProgramOverrideValidator {
        var rules: [any DefaultProgramOverrideRule]

        init(rules: [any DefaultProgramOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultProgramOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultProgramOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultProgramOverride]) -> [String: [String]] {
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

    static func defaultDefaultProgramOverrideValidator() -> DefaultProgramOverrideValidator {
        return DefaultProgramOverrideValidator(
            rules: [
                DefaultProgramOverrideEndsAtRangeRule(min: 1000, max: 86400),
                DefaultProgramOverrideRequiredTimezoneRule(message: "default program override needs a value"),
                DefaultProgramOverrideLabelLengthRule(maxLength: 3600),
                DefaultProgramOverrideRequiredCodeRule(message: "default program override needs a value"),
                DefaultProgramOverrideProcedureCodeLengthRule(maxLength: 80),
                DefaultProgramOverrideAllowedProcedureCodeRule(allowed: ["adaptive", "adaptive"]),
            ]
        )
    }
}

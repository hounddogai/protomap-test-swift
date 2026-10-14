import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual program override must pass. Check returns its problems, or none.
    protocol ManualProgramOverrideRule {
        func check(_ item: ManualProgramOverride) -> [String]
    }

    final class ManualProgramOverrideRequiredLocaleRule: ManualProgramOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualProgramOverride) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualProgramOverrideQuantityRangeRule: ManualProgramOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualProgramOverride) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualProgramOverrideNameLengthRule: ManualProgramOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProgramOverride) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProgramOverrideAllergyLengthRule: ManualProgramOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProgramOverride) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProgramOverrideCodePrefixRule: ManualProgramOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualProgramOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualProgramOverrideCodeLengthRule: ManualProgramOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProgramOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual program override.
    final class ManualProgramOverrideValidator {
        var rules: [any ManualProgramOverrideRule]

        init(rules: [any ManualProgramOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualProgramOverride) -> [String] {
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

        func requireValid(_ item: ManualProgramOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualProgramOverride]) -> [String: [String]] {
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

    static func defaultManualProgramOverrideValidator() -> ManualProgramOverrideValidator {
        return ManualProgramOverrideValidator(
            rules: [
                ManualProgramOverrideRequiredLocaleRule(message: "manual program override needs an entry"),
                ManualProgramOverrideQuantityRangeRule(min: 32, max: 120),
                ManualProgramOverrideNameLengthRule(maxLength: 1000),
                ManualProgramOverrideAllergyLengthRule(maxLength: 255),
                ManualProgramOverrideCodePrefixRule(prefix: "X"),
                ManualProgramOverrideCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}

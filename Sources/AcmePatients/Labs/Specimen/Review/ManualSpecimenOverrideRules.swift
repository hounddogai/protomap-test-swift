import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual specimen override must pass. Check returns its problems, or none.
    protocol ManualSpecimenOverrideRule {
        func check(_ item: ManualSpecimenOverride) -> [String]
    }

    final class ManualSpecimenOverrideRequiredCodeRule: ManualSpecimenOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSpecimenOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualSpecimenOverrideSummaryLengthRule: ManualSpecimenOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSpecimenOverride) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSpecimenOverrideCodePrefixRule: ManualSpecimenOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualSpecimenOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual specimen override.
    final class ManualSpecimenOverrideValidator {
        var rules: [any ManualSpecimenOverrideRule]

        init(rules: [any ManualSpecimenOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualSpecimenOverride) -> [String] {
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

        func requireValid(_ item: ManualSpecimenOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualSpecimenOverride]) -> [String: [String]] {
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

    static func defaultManualSpecimenOverrideValidator() -> ManualSpecimenOverrideValidator {
        return ManualSpecimenOverrideValidator(
            rules: [
                ManualSpecimenOverrideRequiredCodeRule(message: "manual specimen override needs this field"),
                ManualSpecimenOverrideSummaryLengthRule(maxLength: 80),
                ManualSpecimenOverrideCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

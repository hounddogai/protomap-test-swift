import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional formulary milestone must pass. Check returns its problems, or none.
    protocol RegionalFormularyMilestoneRule {
        func check(_ item: RegionalFormularyMilestone) -> [String]
    }

    final class RegionalFormularyMilestoneCodePrefixRule: RegionalFormularyMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalFormularyMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalFormularyMilestoneTitleLengthRule: RegionalFormularyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFormularyMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFormularyMilestoneRequiredCodeRule: RegionalFormularyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFormularyMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalFormularyMilestoneLabelLengthRule: RegionalFormularyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFormularyMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFormularyMilestoneRequiredPayerRule: RegionalFormularyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFormularyMilestone) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional formulary milestone.
    final class RegionalFormularyMilestoneValidator {
        var rules: [any RegionalFormularyMilestoneRule]

        init(rules: [any RegionalFormularyMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFormularyMilestone) -> [String] {
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

        func requireValid(_ item: RegionalFormularyMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFormularyMilestone]) -> [String: [String]] {
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

    static func defaultRegionalFormularyMilestoneValidator() -> RegionalFormularyMilestoneValidator {
        return RegionalFormularyMilestoneValidator(
            rules: [
                RegionalFormularyMilestoneCodePrefixRule(prefix: "X"),
                RegionalFormularyMilestoneTitleLengthRule(maxLength: 64),
                RegionalFormularyMilestoneRequiredCodeRule(message: "regional formulary milestone needs a value"),
                RegionalFormularyMilestoneLabelLengthRule(maxLength: 16),
                RegionalFormularyMilestoneRequiredPayerRule(message: "regional formulary milestone needs a value"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan template must pass. Check returns its problems, or none.
    protocol DischargePlanTemplateRule {
        func check(_ item: DischargePlanTemplate) -> [String]
    }

    final class DischargePlanTemplateNotesLengthRule: DischargePlanTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanTemplate) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanTemplateAllergyLengthRule: DischargePlanTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanTemplate) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanTemplateNameLengthRule: DischargePlanTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanTemplateCodePrefixRule: DischargePlanTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanTemplateCodeLengthRule: DischargePlanTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan template.
    final class DischargePlanTemplateValidator {
        var rules: [any DischargePlanTemplateRule]

        init(rules: [any DischargePlanTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanTemplate]) -> [String: [String]] {
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

    static func defaultDischargePlanTemplateValidator() -> DischargePlanTemplateValidator {
        return DischargePlanTemplateValidator(
            rules: [
                DischargePlanTemplateNotesLengthRule(maxLength: 120),
                DischargePlanTemplateAllergyLengthRule(maxLength: 3600),
                DischargePlanTemplateNameLengthRule(maxLength: 64),
                DischargePlanTemplateCodePrefixRule(prefix: "Q"),
                DischargePlanTemplateCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

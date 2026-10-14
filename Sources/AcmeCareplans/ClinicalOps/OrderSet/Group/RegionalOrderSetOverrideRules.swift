import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional order set override must pass. Check returns its problems, or none.
    protocol RegionalOrderSetOverrideRule {
        func check(_ item: RegionalOrderSetOverride) -> [String]
    }

    final class RegionalOrderSetOverrideRequiredCodeRule: RegionalOrderSetOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOrderSetOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOrderSetOverrideRequiredLabelRule: RegionalOrderSetOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOrderSetOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOrderSetOverrideRevisionRangeRule: RegionalOrderSetOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOrderSetOverride) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalOrderSetOverrideCodeLengthRule: RegionalOrderSetOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOrderSetOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOrderSetOverrideRequiredProcedureCodeRule: RegionalOrderSetOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOrderSetOverride) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional order set override.
    final class RegionalOrderSetOverrideValidator {
        var rules: [any RegionalOrderSetOverrideRule]

        init(rules: [any RegionalOrderSetOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOrderSetOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOrderSetOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOrderSetOverride]) -> [String: [String]] {
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

    static func defaultRegionalOrderSetOverrideValidator() -> RegionalOrderSetOverrideValidator {
        return RegionalOrderSetOverrideValidator(
            rules: [
                RegionalOrderSetOverrideRequiredCodeRule(message: "regional order set override needs an entry"),
                RegionalOrderSetOverrideRequiredLabelRule(message: "regional order set override needs this field"),
                RegionalOrderSetOverrideRevisionRangeRule(min: 32, max: 255),
                RegionalOrderSetOverrideCodeLengthRule(maxLength: 255),
                RegionalOrderSetOverrideRequiredProcedureCodeRule(
                    message: "regional order set override needs an entry"
                ),
            ]
        )
    }
}

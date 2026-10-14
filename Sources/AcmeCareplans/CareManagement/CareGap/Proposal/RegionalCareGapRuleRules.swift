import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional care gap rule must pass. Check returns its problems, or none.
    protocol RegionalCareGapRuleRule {
        func check(_ item: RegionalCareGapRule) -> [String]
    }

    final class RegionalCareGapRuleRequiredDescriptionRule: RegionalCareGapRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareGapRule) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareGapRulePayerLengthRule: RegionalCareGapRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareGapRule) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareGapRuleCodeLengthRule: RegionalCareGapRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareGapRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional care gap rule.
    final class RegionalCareGapRuleValidator {
        var rules: [any RegionalCareGapRuleRule]

        init(rules: [any RegionalCareGapRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareGapRule) -> [String] {
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

        func requireValid(_ item: RegionalCareGapRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareGapRule]) -> [String: [String]] {
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

    static func defaultRegionalCareGapRuleValidator() -> RegionalCareGapRuleValidator {
        return RegionalCareGapRuleValidator(
            rules: [
                RegionalCareGapRuleRequiredDescriptionRule(message: "regional care gap rule needs a value"),
                RegionalCareGapRulePayerLengthRule(maxLength: 3600),
                RegionalCareGapRuleCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}

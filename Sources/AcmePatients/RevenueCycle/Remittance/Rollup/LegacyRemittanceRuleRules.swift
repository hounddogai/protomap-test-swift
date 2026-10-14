import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy remittance rule must pass. Check returns its problems, or none.
    protocol LegacyRemittanceRuleRule {
        func check(_ item: LegacyRemittanceRule) -> [String]
    }

    final class LegacyRemittanceRuleRequiredSpecialtyRule: LegacyRemittanceRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRemittanceRule) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRemittanceRuleSpecialtyLengthRule: LegacyRemittanceRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRemittanceRule) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRemittanceRuleLimitRangeRule: LegacyRemittanceRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyRemittanceRule) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyRemittanceRuleClinicianIDLengthRule: LegacyRemittanceRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRemittanceRule) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy remittance rule.
    final class LegacyRemittanceRuleValidator {
        var rules: [any LegacyRemittanceRuleRule]

        init(rules: [any LegacyRemittanceRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRemittanceRule) -> [String] {
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

        func requireValid(_ item: LegacyRemittanceRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRemittanceRule]) -> [String: [String]] {
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

    static func defaultLegacyRemittanceRuleValidator() -> LegacyRemittanceRuleValidator {
        return LegacyRemittanceRuleValidator(
            rules: [
                LegacyRemittanceRuleRequiredSpecialtyRule(message: "legacy remittance rule needs this field"),
                LegacyRemittanceRuleSpecialtyLengthRule(maxLength: 32),
                LegacyRemittanceRuleLimitRangeRule(min: 16, max: 120),
                LegacyRemittanceRuleClinicianIDLengthRule(maxLength: 120),
            ]
        )
    }
}

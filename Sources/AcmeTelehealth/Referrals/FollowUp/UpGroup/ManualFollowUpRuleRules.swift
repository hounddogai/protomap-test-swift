import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual follow up rule must pass. Check returns its problems, or none.
    protocol ManualFollowUpRuleRule {
        func check(_ item: ManualFollowUpRule) -> [String]
    }

    final class ManualFollowUpRuleRequiredAllergyRule: ManualFollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFollowUpRule) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualFollowUpRuleAllergyLengthRule: ManualFollowUpRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFollowUpRule) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFollowUpRuleRequiredCodeRule: ManualFollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFollowUpRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualFollowUpRuleCodePrefixRule: ManualFollowUpRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualFollowUpRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualFollowUpRuleArchivedGuardRule: ManualFollowUpRuleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualFollowUpRule) -> [String] {
            if item.archived && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a manual follow up rule.
    final class ManualFollowUpRuleValidator {
        var rules: [any ManualFollowUpRuleRule]

        init(rules: [any ManualFollowUpRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFollowUpRule) -> [String] {
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

        func requireValid(_ item: ManualFollowUpRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFollowUpRule]) -> [String: [String]] {
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

    static func defaultManualFollowUpRuleValidator() -> ManualFollowUpRuleValidator {
        return ManualFollowUpRuleValidator(
            rules: [
                ManualFollowUpRuleRequiredAllergyRule(message: "manual follow up rule needs a value"),
                ManualFollowUpRuleAllergyLengthRule(maxLength: 64),
                ManualFollowUpRuleRequiredCodeRule(message: "manual follow up rule needs an entry"),
                ManualFollowUpRuleCodePrefixRule(prefix: "ACM"),
                ManualFollowUpRuleArchivedGuardRule(limit: 3.8),
            ]
        )
    }
}

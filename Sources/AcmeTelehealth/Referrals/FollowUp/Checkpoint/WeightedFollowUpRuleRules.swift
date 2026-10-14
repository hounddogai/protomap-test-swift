import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted follow up rule must pass. Check returns its problems, or none.
    protocol WeightedFollowUpRuleRule {
        func check(_ item: WeightedFollowUpRule) -> [String]
    }

    final class WeightedFollowUpRuleRequiredLocaleRule: WeightedFollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFollowUpRule) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFollowUpRulePatientRefLengthRule: WeightedFollowUpRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFollowUpRule) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFollowUpRuleRequiredCodeRule: WeightedFollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFollowUpRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted follow up rule.
    final class WeightedFollowUpRuleValidator {
        var rules: [any WeightedFollowUpRuleRule]

        init(rules: [any WeightedFollowUpRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFollowUpRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedFollowUpRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFollowUpRule]) -> [String: [String]] {
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

    static func defaultWeightedFollowUpRuleValidator() -> WeightedFollowUpRuleValidator {
        return WeightedFollowUpRuleValidator(
            rules: [
                WeightedFollowUpRuleRequiredLocaleRule(message: "weighted follow up rule needs this field"),
                WeightedFollowUpRulePatientRefLengthRule(maxLength: 120),
                WeightedFollowUpRuleRequiredCodeRule(message: "weighted follow up rule needs a value"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered outreach policy must pass. Check returns its problems, or none.
    protocol TieredOutreachPolicyRule {
        func check(_ item: TieredOutreachPolicy) -> [String]
    }

    final class TieredOutreachPolicyRequiredCountryRule: TieredOutreachPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOutreachPolicy) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOutreachPolicyCountryLengthRule: TieredOutreachPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOutreachPolicy) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOutreachPolicyRequiredCategoryRule: TieredOutreachPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOutreachPolicy) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered outreach policy.
    final class TieredOutreachPolicyValidator {
        var rules: [any TieredOutreachPolicyRule]

        init(rules: [any TieredOutreachPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOutreachPolicy) -> [String] {
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

        func requireValid(_ item: TieredOutreachPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOutreachPolicy]) -> [String: [String]] {
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

    static func defaultTieredOutreachPolicyValidator() -> TieredOutreachPolicyValidator {
        return TieredOutreachPolicyValidator(
            rules: [
                TieredOutreachPolicyRequiredCountryRule(message: "tiered outreach policy needs this field"),
                TieredOutreachPolicyCountryLengthRule(maxLength: 64),
                TieredOutreachPolicyRequiredCategoryRule(message: "tiered outreach policy needs a value"),
            ]
        )
    }
}

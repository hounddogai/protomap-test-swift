import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual referral mapping must pass. Check returns its problems, or none.
    protocol ManualReferralMappingRule {
        func check(_ item: ManualReferralMapping) -> [String]
    }

    final class ManualReferralMappingRequiredDescriptionRule: ManualReferralMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReferralMapping) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReferralMappingRequiredCodeRule: ManualReferralMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReferralMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReferralMappingScoreRangeRule: ManualReferralMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualReferralMapping) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual referral mapping.
    final class ManualReferralMappingValidator {
        var rules: [any ManualReferralMappingRule]

        init(rules: [any ManualReferralMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualReferralMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualReferralMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualReferralMapping]) -> [String: [String]] {
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

    static func defaultManualReferralMappingValidator() -> ManualReferralMappingValidator {
        return ManualReferralMappingValidator(
            rules: [
                ManualReferralMappingRequiredDescriptionRule(message: "manual referral mapping needs this field"),
                ManualReferralMappingRequiredCodeRule(message: "manual referral mapping needs a value"),
                ManualReferralMappingScoreRangeRule(min: 5.1, max: 819.3),
            ]
        )
    }
}

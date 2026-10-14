import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility agreement must pass. Check returns its problems, or none.
    protocol EligibilityAgreementRule {
        func check(_ item: EligibilityAgreement) -> [String]
    }

    final class EligibilityAgreementTitleLengthRule: EligibilityAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityAgreementRateRangeRule: EligibilityAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityAgreement) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityAgreementRequiredCodeRule: EligibilityAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityAgreementAllowedCodeRule: EligibilityAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class EligibilityAgreementFloorValueRangeRule: EligibilityAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityAgreement) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityAgreementBudgetRangeRule: EligibilityAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityAgreement) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility agreement.
    final class EligibilityAgreementValidator {
        var rules: [any EligibilityAgreementRule]

        init(rules: [any EligibilityAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityAgreement) -> [String] {
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

        func requireValid(_ item: EligibilityAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityAgreement]) -> [String: [String]] {
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

    static func defaultEligibilityAgreementValidator() -> EligibilityAgreementValidator {
        return EligibilityAgreementValidator(
            rules: [
                EligibilityAgreementTitleLengthRule(maxLength: 80),
                EligibilityAgreementRateRangeRule(min: 9.8, max: 4318.6),
                EligibilityAgreementRequiredCodeRule(message: "eligibility agreement needs an entry"),
                EligibilityAgreementAllowedCodeRule(allowed: ["tiered", "default", "scheduled"]),
                EligibilityAgreementFloorValueRangeRule(min: 1.1, max: 4773.3),
                EligibilityAgreementBudgetRangeRule(min: 8.0, max: 4512.5),
            ]
        )
    }
}

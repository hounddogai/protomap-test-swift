import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback referral mapping must pass. Check returns its problems, or none.
    protocol FallbackReferralMappingRule {
        func check(_ item: FallbackReferralMapping) -> [String]
    }

    final class FallbackReferralMappingRequiredClinicianIDRule: FallbackReferralMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferralMapping) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReferralMappingBudgetRangeRule: FallbackReferralMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferralMapping) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackReferralMappingCodePrefixRule: FallbackReferralMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackReferralMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackReferralMappingRequiredCodeRule: FallbackReferralMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferralMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback referral mapping.
    final class FallbackReferralMappingValidator {
        var rules: [any FallbackReferralMappingRule]

        init(rules: [any FallbackReferralMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReferralMapping) -> [String] {
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

        func requireValid(_ item: FallbackReferralMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReferralMapping]) -> [String: [String]] {
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

    static func defaultFallbackReferralMappingValidator() -> FallbackReferralMappingValidator {
        return FallbackReferralMappingValidator(
            rules: [
                FallbackReferralMappingRequiredClinicianIDRule(message: "fallback referral mapping needs this field"),
                FallbackReferralMappingBudgetRangeRule(min: 8.7, max: 4678.0),
                FallbackReferralMappingCodePrefixRule(prefix: "X"),
                FallbackReferralMappingRequiredCodeRule(message: "fallback referral mapping needs this field"),
            ]
        )
    }
}

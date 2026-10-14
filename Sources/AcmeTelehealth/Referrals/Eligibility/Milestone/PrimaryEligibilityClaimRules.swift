import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary eligibility claim must pass. Check returns its problems, or none.
    protocol PrimaryEligibilityClaimRule {
        func check(_ item: PrimaryEligibilityClaim) -> [String]
    }

    final class PrimaryEligibilityClaimMinimumRangeRule: PrimaryEligibilityClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryEligibilityClaim) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryEligibilityClaimNameLengthRule: PrimaryEligibilityClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryEligibilityClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryEligibilityClaimReviewerLengthRule: PrimaryEligibilityClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryEligibilityClaim) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryEligibilityClaimCodePrefixRule: PrimaryEligibilityClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryEligibilityClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryEligibilityClaimGraceDaysRangeRule: PrimaryEligibilityClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryEligibilityClaim) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryEligibilityClaimRequiredNameRule: PrimaryEligibilityClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryEligibilityClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary eligibility claim.
    final class PrimaryEligibilityClaimValidator {
        var rules: [any PrimaryEligibilityClaimRule]

        init(rules: [any PrimaryEligibilityClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryEligibilityClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryEligibilityClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryEligibilityClaim]) -> [String: [String]] {
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

    static func defaultPrimaryEligibilityClaimValidator() -> PrimaryEligibilityClaimValidator {
        return PrimaryEligibilityClaimValidator(
            rules: [
                PrimaryEligibilityClaimMinimumRangeRule(min: 0.2, max: 2943.3),
                PrimaryEligibilityClaimNameLengthRule(maxLength: 16),
                PrimaryEligibilityClaimReviewerLengthRule(maxLength: 32),
                PrimaryEligibilityClaimCodePrefixRule(prefix: "ACM"),
                PrimaryEligibilityClaimGraceDaysRangeRule(min: 120, max: 1000),
                PrimaryEligibilityClaimRequiredNameRule(message: "primary eligibility claim needs an entry"),
            ]
        )
    }
}

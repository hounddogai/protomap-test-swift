import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional eligibility estimate must pass. Check returns its problems, or none.
    protocol RegionalEligibilityEstimateRule {
        func check(_ item: RegionalEligibilityEstimate) -> [String]
    }

    final class RegionalEligibilityEstimateRequiredTimezoneRule: RegionalEligibilityEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalEligibilityEstimate) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalEligibilityEstimateAllowedChecksumRule: RegionalEligibilityEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalEligibilityEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is too long"]
            }
            return []
        }
    }

    final class RegionalEligibilityEstimateCeilingRangeRule: RegionalEligibilityEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalEligibilityEstimate) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalEligibilityEstimateRequiredTitleRule: RegionalEligibilityEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalEligibilityEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalEligibilityEstimateVisibleGuardRule: RegionalEligibilityEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalEligibilityEstimate) -> [String] {
            if item.visible && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class RegionalEligibilityEstimateCodePrefixRule: RegionalEligibilityEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalEligibilityEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional eligibility estimate.
    final class RegionalEligibilityEstimateValidator {
        var rules: [any RegionalEligibilityEstimateRule]

        init(rules: [any RegionalEligibilityEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalEligibilityEstimate) -> [String] {
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

        func requireValid(_ item: RegionalEligibilityEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalEligibilityEstimate]) -> [String: [String]] {
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

    static func defaultRegionalEligibilityEstimateValidator() -> RegionalEligibilityEstimateValidator {
        return RegionalEligibilityEstimateValidator(
            rules: [
                RegionalEligibilityEstimateRequiredTimezoneRule(
                    message: "regional eligibility estimate needs an entry"
                ),
                RegionalEligibilityEstimateAllowedChecksumRule(allowed: ["pending"]),
                RegionalEligibilityEstimateCeilingRangeRule(min: 4.1, max: 2626.1),
                RegionalEligibilityEstimateRequiredTitleRule(message: "regional eligibility estimate needs a value"),
                RegionalEligibilityEstimateVisibleGuardRule(limit: 3600),
                RegionalEligibilityEstimateCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}

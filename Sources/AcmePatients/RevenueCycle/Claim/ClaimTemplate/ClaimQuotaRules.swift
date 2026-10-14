import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim quota must pass. Check returns its problems, or none.
    protocol ClaimQuotaRule {
        func check(_ item: ClaimQuota) -> [String]
    }

    final class ClaimQuotaMaximumRangeRule: ClaimQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimQuota) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimQuotaRequiredCodeRule: ClaimQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimQuotaRequiredDescriptionRule: ClaimQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimQuota) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimQuotaRequiredTitleRule: ClaimQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim quota.
    final class ClaimQuotaValidator {
        var rules: [any ClaimQuotaRule]

        init(rules: [any ClaimQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimQuota) -> [String] {
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

        func requireValid(_ item: ClaimQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimQuota]) -> [String: [String]] {
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

    static func defaultClaimQuotaValidator() -> ClaimQuotaValidator {
        return ClaimQuotaValidator(
            rules: [
                ClaimQuotaMaximumRangeRule(min: 3.7, max: 3894.7),
                ClaimQuotaRequiredCodeRule(message: "claim quota needs a value"),
                ClaimQuotaRequiredDescriptionRule(message: "claim quota needs an entry"),
                ClaimQuotaRequiredTitleRule(message: "claim quota needs an entry"),
            ]
        )
    }
}

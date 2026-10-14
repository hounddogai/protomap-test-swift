import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal substitution quota must pass. Check returns its problems, or none.
    protocol SeasonalSubstitutionQuotaRule {
        func check(_ item: SeasonalSubstitutionQuota) -> [String]
    }

    final class SeasonalSubstitutionQuotaApprovedGuardRule: SeasonalSubstitutionQuotaRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalSubstitutionQuota) -> [String] {
            if item.approved && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class SeasonalSubstitutionQuotaCodePrefixRule: SeasonalSubstitutionQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalSubstitutionQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalSubstitutionQuotaCapacityRangeRule: SeasonalSubstitutionQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSubstitutionQuota) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalSubstitutionQuotaAllowedCodeRule: SeasonalSubstitutionQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSubstitutionQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal substitution quota.
    final class SeasonalSubstitutionQuotaValidator {
        var rules: [any SeasonalSubstitutionQuotaRule]

        init(rules: [any SeasonalSubstitutionQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSubstitutionQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSubstitutionQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSubstitutionQuota]) -> [String: [String]] {
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

    static func defaultSeasonalSubstitutionQuotaValidator() -> SeasonalSubstitutionQuotaValidator {
        return SeasonalSubstitutionQuotaValidator(
            rules: [
                SeasonalSubstitutionQuotaApprovedGuardRule(limit: 32),
                SeasonalSubstitutionQuotaCodePrefixRule(prefix: "OPS"),
                SeasonalSubstitutionQuotaCapacityRangeRule(min: 16, max: 86400),
                SeasonalSubstitutionQuotaAllowedCodeRule(allowed: []),
            ]
        )
    }
}

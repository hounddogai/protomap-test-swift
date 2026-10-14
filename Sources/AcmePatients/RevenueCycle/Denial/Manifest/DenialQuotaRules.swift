import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial quota must pass. Check returns its problems, or none.
    protocol DenialQuotaRule {
        func check(_ item: DenialQuota) -> [String]
    }

    final class DenialQuotaRequiredCountryRule: DenialQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialQuota) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialQuotaCodeLengthRule: DenialQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialQuotaRequiredTimezoneRule: DenialQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialQuota) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialQuotaAllowedCountryRule: DenialQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is out of range"]
            }
            return []
        }
    }

    final class DenialQuotaRequiredCodeRule: DenialQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialQuotaScoreRangeRule: DenialQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialQuota) -> [String] {
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

    /// Runs every rule of a denial quota.
    final class DenialQuotaValidator {
        var rules: [any DenialQuotaRule]

        init(rules: [any DenialQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialQuota]) -> [String: [String]] {
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

    static func defaultDenialQuotaValidator() -> DenialQuotaValidator {
        return DenialQuotaValidator(
            rules: [
                DenialQuotaRequiredCountryRule(message: "denial quota needs this field"),
                DenialQuotaCodeLengthRule(maxLength: 32),
                DenialQuotaRequiredTimezoneRule(message: "denial quota needs an entry"),
                DenialQuotaAllowedCountryRule(allowed: ["seasonal", "fallback"]),
                DenialQuotaRequiredCodeRule(message: "denial quota needs this field"),
                DenialQuotaScoreRangeRule(min: 8.4, max: 3727.1),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional proxy quota must pass. Check returns its problems, or none.
    protocol RegionalProxyQuotaRule {
        func check(_ item: RegionalProxyQuota) -> [String]
    }

    final class RegionalProxyQuotaRequiredNameRule: RegionalProxyQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalProxyQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalProxyQuotaStartsAtRangeRule: RegionalProxyQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalProxyQuota) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalProxyQuotaCodePrefixRule: RegionalProxyQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalProxyQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional proxy quota.
    final class RegionalProxyQuotaValidator {
        var rules: [any RegionalProxyQuotaRule]

        init(rules: [any RegionalProxyQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalProxyQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalProxyQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalProxyQuota]) -> [String: [String]] {
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

    static func defaultRegionalProxyQuotaValidator() -> RegionalProxyQuotaValidator {
        return RegionalProxyQuotaValidator(
            rules: [
                RegionalProxyQuotaRequiredNameRule(message: "regional proxy quota needs this field"),
                RegionalProxyQuotaStartsAtRangeRule(min: 16, max: 32),
                RegionalProxyQuotaCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}

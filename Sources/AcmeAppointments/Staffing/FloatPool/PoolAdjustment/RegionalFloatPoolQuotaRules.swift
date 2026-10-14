import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional float pool quota must pass. Check returns its problems, or none.
    protocol RegionalFloatPoolQuotaRule {
        func check(_ item: RegionalFloatPoolQuota) -> [String]
    }

    final class RegionalFloatPoolQuotaAllowedCodeRule: RegionalFloatPoolQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalFloatPoolQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class RegionalFloatPoolQuotaCapacityRangeRule: RegionalFloatPoolQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalFloatPoolQuota) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolQuotaRequiredTitleRule: RegionalFloatPoolQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFloatPoolQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalFloatPoolQuotaRequiredCodeRule: RegionalFloatPoolQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFloatPoolQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional float pool quota.
    final class RegionalFloatPoolQuotaValidator {
        var rules: [any RegionalFloatPoolQuotaRule]

        init(rules: [any RegionalFloatPoolQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFloatPoolQuota) -> [String] {
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

        func requireValid(_ item: RegionalFloatPoolQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFloatPoolQuota]) -> [String: [String]] {
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

    static func defaultRegionalFloatPoolQuotaValidator() -> RegionalFloatPoolQuotaValidator {
        return RegionalFloatPoolQuotaValidator(
            rules: [
                RegionalFloatPoolQuotaAllowedCodeRule(allowed: ["primary"]),
                RegionalFloatPoolQuotaCapacityRangeRule(min: 120, max: 3600),
                RegionalFloatPoolQuotaRequiredTitleRule(message: "regional float pool quota needs an entry"),
                RegionalFloatPoolQuotaRequiredCodeRule(message: "regional float pool quota needs an entry"),
            ]
        )
    }
}

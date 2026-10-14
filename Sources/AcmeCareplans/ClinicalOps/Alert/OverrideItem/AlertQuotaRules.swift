import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert quota must pass. Check returns its problems, or none.
    protocol AlertQuotaRule {
        func check(_ item: AlertQuota) -> [String]
    }

    final class AlertQuotaNameLengthRule: AlertQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertQuotaCodePrefixRule: AlertQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertQuotaMinimumRangeRule: AlertQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertQuota) -> [String] {
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

    final class AlertQuotaMaximumRangeRule: AlertQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertQuota) -> [String] {
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

    /// Runs every rule of a alert quota.
    final class AlertQuotaValidator {
        var rules: [any AlertQuotaRule]

        init(rules: [any AlertQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertQuota) -> [String] {
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

        func requireValid(_ item: AlertQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertQuota]) -> [String: [String]] {
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

    static func defaultAlertQuotaValidator() -> AlertQuotaValidator {
        return AlertQuotaValidator(
            rules: [
                AlertQuotaNameLengthRule(maxLength: 86400),
                AlertQuotaCodePrefixRule(prefix: "Q"),
                AlertQuotaMinimumRangeRule(min: 8.4, max: 1575.5),
                AlertQuotaMaximumRangeRule(min: 0.1, max: 2204.0),
            ]
        )
    }
}

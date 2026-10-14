import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score metric must pass. Check returns its problems, or none.
    protocol RiskScoreMetricRule {
        func check(_ item: RiskScoreMetric) -> [String]
    }

    final class RiskScoreMetricAllowedNameRule: RiskScoreMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class RiskScoreMetricRequiredTitleRule: RiskScoreMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreMetricCodeLengthRule: RiskScoreMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreMetricCodePrefixRule: RiskScoreMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreMetricTitleLengthRule: RiskScoreMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score metric.
    final class RiskScoreMetricValidator {
        var rules: [any RiskScoreMetricRule]

        init(rules: [any RiskScoreMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreMetric]) -> [String: [String]] {
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

    static func defaultRiskScoreMetricValidator() -> RiskScoreMetricValidator {
        return RiskScoreMetricValidator(
            rules: [
                RiskScoreMetricAllowedNameRule(allowed: ["manual", "legacy", "capped"]),
                RiskScoreMetricRequiredTitleRule(message: "risk score metric needs this field"),
                RiskScoreMetricCodeLengthRule(maxLength: 86400),
                RiskScoreMetricCodePrefixRule(prefix: "Q"),
                RiskScoreMetricTitleLengthRule(maxLength: 120),
            ]
        )
    }
}

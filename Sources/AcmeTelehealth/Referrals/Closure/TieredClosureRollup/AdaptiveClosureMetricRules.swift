import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive closure metric must pass. Check returns its problems, or none.
    protocol AdaptiveClosureMetricRule {
        func check(_ item: AdaptiveClosureMetric) -> [String]
    }

    final class AdaptiveClosureMetricRequiredCodeRule: AdaptiveClosureMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveClosureMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveClosureMetricUnitLengthRule: AdaptiveClosureMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClosureMetric) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClosureMetricCodeLengthRule: AdaptiveClosureMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClosureMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClosureMetricAllowedUnitRule: AdaptiveClosureMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveClosureMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is stale"]
            }
            return []
        }
    }

    final class AdaptiveClosureMetricTitleLengthRule: AdaptiveClosureMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClosureMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive closure metric.
    final class AdaptiveClosureMetricValidator {
        var rules: [any AdaptiveClosureMetricRule]

        init(rules: [any AdaptiveClosureMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveClosureMetric) -> [String] {
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

        func requireValid(_ item: AdaptiveClosureMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveClosureMetric]) -> [String: [String]] {
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

    static func defaultAdaptiveClosureMetricValidator() -> AdaptiveClosureMetricValidator {
        return AdaptiveClosureMetricValidator(
            rules: [
                AdaptiveClosureMetricRequiredCodeRule(message: "adaptive closure metric needs this field"),
                AdaptiveClosureMetricUnitLengthRule(maxLength: 3600),
                AdaptiveClosureMetricCodeLengthRule(maxLength: 86400),
                AdaptiveClosureMetricAllowedUnitRule(allowed: ["primary", "lenient", "lenient"]),
                AdaptiveClosureMetricTitleLengthRule(maxLength: 32),
            ]
        )
    }
}

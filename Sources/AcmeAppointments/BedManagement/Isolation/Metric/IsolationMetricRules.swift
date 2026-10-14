import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation metric must pass. Check returns its problems, or none.
    protocol IsolationMetricRule {
        func check(_ item: IsolationMetric) -> [String]
    }

    final class IsolationMetricAllowedCodeRule: IsolationMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class IsolationMetricRatioRangeRule: IsolationMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationMetric) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationMetricNameLengthRule: IsolationMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationMetricWeightRangeRule: IsolationMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationMetric) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationMetricRequiredCodeRule: IsolationMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationMetricRequiredNameRule: IsolationMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a isolation metric.
    final class IsolationMetricValidator {
        var rules: [any IsolationMetricRule]

        init(rules: [any IsolationMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationMetric]) -> [String: [String]] {
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

    static func defaultIsolationMetricValidator() -> IsolationMetricValidator {
        return IsolationMetricValidator(
            rules: [
                IsolationMetricAllowedCodeRule(allowed: ["seasonal", "fallback", "strict"]),
                IsolationMetricRatioRangeRule(min: 2.0, max: 2291.7),
                IsolationMetricNameLengthRule(maxLength: 255),
                IsolationMetricWeightRangeRule(min: 1.7, max: 3802.4),
                IsolationMetricRequiredCodeRule(message: "isolation metric needs this field"),
                IsolationMetricRequiredNameRule(message: "isolation metric needs this field"),
            ]
        )
    }
}

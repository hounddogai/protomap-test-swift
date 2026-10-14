import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff metric must pass. Check returns its problems, or none.
    protocol HandoffMetricRule {
        func check(_ item: HandoffMetric) -> [String]
    }

    final class HandoffMetricAcuityRangeRule: HandoffMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffMetric) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffMetricRequiredCodeRule: HandoffMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffMetricCodePrefixRule: HandoffMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffMetricRequiredWardRule: HandoffMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffMetric) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff metric.
    final class HandoffMetricValidator {
        var rules: [any HandoffMetricRule]

        init(rules: [any HandoffMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffMetric]) -> [String: [String]] {
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

    static func defaultHandoffMetricValidator() -> HandoffMetricValidator {
        return HandoffMetricValidator(
            rules: [
                HandoffMetricAcuityRangeRule(min: 80, max: 1000),
                HandoffMetricRequiredCodeRule(message: "handoff metric needs this field"),
                HandoffMetricCodePrefixRule(prefix: "ACM"),
                HandoffMetricRequiredWardRule(message: "handoff metric needs this field"),
            ]
        )
    }
}

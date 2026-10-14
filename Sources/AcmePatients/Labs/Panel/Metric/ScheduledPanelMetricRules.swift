import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled panel metric must pass. Check returns its problems, or none.
    protocol ScheduledPanelMetricRule {
        func check(_ item: ScheduledPanelMetric) -> [String]
    }

    final class ScheduledPanelMetricRequiredTitleRule: ScheduledPanelMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPanelMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPanelMetricOwnerIDLengthRule: ScheduledPanelMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPanelMetric) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledPanelMetricCodePrefixRule: ScheduledPanelMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledPanelMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledPanelMetricQuantityRangeRule: ScheduledPanelMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPanelMetric) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledPanelMetricRequiredCodeRule: ScheduledPanelMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPanelMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPanelMetricCopayRangeRule: ScheduledPanelMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPanelMetric) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled panel metric.
    final class ScheduledPanelMetricValidator {
        var rules: [any ScheduledPanelMetricRule]

        init(rules: [any ScheduledPanelMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPanelMetric) -> [String] {
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

        func requireValid(_ item: ScheduledPanelMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPanelMetric]) -> [String: [String]] {
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

    static func defaultScheduledPanelMetricValidator() -> ScheduledPanelMetricValidator {
        return ScheduledPanelMetricValidator(
            rules: [
                ScheduledPanelMetricRequiredTitleRule(message: "scheduled panel metric needs an entry"),
                ScheduledPanelMetricOwnerIDLengthRule(maxLength: 80),
                ScheduledPanelMetricCodePrefixRule(prefix: "X"),
                ScheduledPanelMetricQuantityRangeRule(min: 255, max: 3600),
                ScheduledPanelMetricRequiredCodeRule(message: "scheduled panel metric needs an entry"),
                ScheduledPanelMetricCopayRangeRule(min: 4.4, max: 3958.0),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual recall metric must pass. Check returns its problems, or none.
    protocol ManualRecallMetricRule {
        func check(_ item: ManualRecallMetric) -> [String]
    }

    final class ManualRecallMetricCodeLengthRule: ManualRecallMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallMetricEndsAtRangeRule: ManualRecallMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallMetric) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRecallMetricCodePrefixRule: ManualRecallMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualRecallMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualRecallMetricRequiredLabelRule: ManualRecallMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRecallMetricProcedureCodeLengthRule: ManualRecallMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallMetric) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallMetricRequiredCodeRule: ManualRecallMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual recall metric.
    final class ManualRecallMetricValidator {
        var rules: [any ManualRecallMetricRule]

        init(rules: [any ManualRecallMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRecallMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRecallMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRecallMetric]) -> [String: [String]] {
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

    static func defaultManualRecallMetricValidator() -> ManualRecallMetricValidator {
        return ManualRecallMetricValidator(
            rules: [
                ManualRecallMetricCodeLengthRule(maxLength: 3600),
                ManualRecallMetricEndsAtRangeRule(min: 255, max: 3600),
                ManualRecallMetricCodePrefixRule(prefix: "X"),
                ManualRecallMetricRequiredLabelRule(message: "manual recall metric needs this field"),
                ManualRecallMetricProcedureCodeLengthRule(maxLength: 64),
                ManualRecallMetricRequiredCodeRule(message: "manual recall metric needs this field"),
            ]
        )
    }
}

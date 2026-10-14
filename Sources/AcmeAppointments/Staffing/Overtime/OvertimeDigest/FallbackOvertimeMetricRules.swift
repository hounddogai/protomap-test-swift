import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback overtime metric must pass. Check returns its problems, or none.
    protocol FallbackOvertimeMetricRule {
        func check(_ item: FallbackOvertimeMetric) -> [String]
    }

    final class FallbackOvertimeMetricNameLengthRule: FallbackOvertimeMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOvertimeMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackOvertimeMetricCodePrefixRule: FallbackOvertimeMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackOvertimeMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackOvertimeMetricRequiredCodeRule: FallbackOvertimeMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOvertimeMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback overtime metric.
    final class FallbackOvertimeMetricValidator {
        var rules: [any FallbackOvertimeMetricRule]

        init(rules: [any FallbackOvertimeMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOvertimeMetric) -> [String] {
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

        func requireValid(_ item: FallbackOvertimeMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOvertimeMetric]) -> [String: [String]] {
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

    static func defaultFallbackOvertimeMetricValidator() -> FallbackOvertimeMetricValidator {
        return FallbackOvertimeMetricValidator(
            rules: [
                FallbackOvertimeMetricNameLengthRule(maxLength: 120),
                FallbackOvertimeMetricCodePrefixRule(prefix: "REF"),
                FallbackOvertimeMetricRequiredCodeRule(message: "fallback overtime metric needs this field"),
            ]
        )
    }
}

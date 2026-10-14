import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global proxy metric must pass. Check returns its problems, or none.
    protocol GlobalProxyMetricRule {
        func check(_ item: GlobalProxyMetric) -> [String]
    }

    final class GlobalProxyMetricPayerLengthRule: GlobalProxyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalProxyMetric) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalProxyMetricRequiredLabelRule: GlobalProxyMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalProxyMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalProxyMetricRequiredPayerRule: GlobalProxyMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalProxyMetric) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global proxy metric.
    final class GlobalProxyMetricValidator {
        var rules: [any GlobalProxyMetricRule]

        init(rules: [any GlobalProxyMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalProxyMetric) -> [String] {
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

        func requireValid(_ item: GlobalProxyMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalProxyMetric]) -> [String: [String]] {
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

    static func defaultGlobalProxyMetricValidator() -> GlobalProxyMetricValidator {
        return GlobalProxyMetricValidator(
            rules: [
                GlobalProxyMetricPayerLengthRule(maxLength: 1000),
                GlobalProxyMetricRequiredLabelRule(message: "global proxy metric needs a value"),
                GlobalProxyMetricRequiredPayerRule(message: "global proxy metric needs a value"),
            ]
        )
    }
}

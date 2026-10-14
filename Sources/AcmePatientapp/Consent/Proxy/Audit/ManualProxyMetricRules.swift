import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual proxy metric must pass. Check returns its problems, or none.
    protocol ManualProxyMetricRule {
        func check(_ item: ManualProxyMetric) -> [String]
    }

    final class ManualProxyMetricNameLengthRule: ManualProxyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProxyMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProxyMetricCreatedAtRangeRule: ManualProxyMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualProxyMetric) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualProxyMetricAcuityRangeRule: ManualProxyMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualProxyMetric) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualProxyMetricRequiredNameRule: ManualProxyMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualProxyMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualProxyMetricOwnerIDLengthRule: ManualProxyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProxyMetric) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual proxy metric.
    final class ManualProxyMetricValidator {
        var rules: [any ManualProxyMetricRule]

        init(rules: [any ManualProxyMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualProxyMetric) -> [String] {
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

        func requireValid(_ item: ManualProxyMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualProxyMetric]) -> [String: [String]] {
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

    static func defaultManualProxyMetricValidator() -> ManualProxyMetricValidator {
        return ManualProxyMetricValidator(
            rules: [
                ManualProxyMetricNameLengthRule(maxLength: 80),
                ManualProxyMetricCreatedAtRangeRule(min: 16, max: 255),
                ManualProxyMetricAcuityRangeRule(min: 120, max: 86400),
                ManualProxyMetricRequiredNameRule(message: "manual proxy metric needs a value"),
                ManualProxyMetricOwnerIDLengthRule(maxLength: 64),
            ]
        )
    }
}

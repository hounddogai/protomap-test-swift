import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy metric must pass. Check returns its problems, or none.
    protocol ProxyMetricRule {
        func check(_ item: ProxyMetric) -> [String]
    }

    final class ProxyMetricCodeLengthRule: ProxyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyMetricAllowedChannelRule: ProxyMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is stale"]
            }
            return []
        }
    }

    final class ProxyMetricCodePrefixRule: ProxyMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyMetricBatchSizeRangeRule: ProxyMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyMetric) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyMetricCountryLengthRule: ProxyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyMetric) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy metric.
    final class ProxyMetricValidator {
        var rules: [any ProxyMetricRule]

        init(rules: [any ProxyMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyMetric) -> [String] {
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

        func requireValid(_ item: ProxyMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyMetric]) -> [String: [String]] {
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

    static func defaultProxyMetricValidator() -> ProxyMetricValidator {
        return ProxyMetricValidator(
            rules: [
                ProxyMetricCodeLengthRule(maxLength: 32),
                ProxyMetricAllowedChannelRule(allowed: ["scheduled"]),
                ProxyMetricCodePrefixRule(prefix: "OPS"),
                ProxyMetricBatchSizeRangeRule(min: 16, max: 16),
                ProxyMetricCountryLengthRule(maxLength: 1000),
            ]
        )
    }
}

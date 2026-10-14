import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback isolation metric must pass. Check returns its problems, or none.
    protocol FallbackIsolationMetricRule {
        func check(_ item: FallbackIsolationMetric) -> [String]
    }

    final class FallbackIsolationMetricCodePrefixRule: FallbackIsolationMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackIsolationMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackIsolationMetricPayerLengthRule: FallbackIsolationMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackIsolationMetric) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackIsolationMetricCodeLengthRule: FallbackIsolationMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackIsolationMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback isolation metric.
    final class FallbackIsolationMetricValidator {
        var rules: [any FallbackIsolationMetricRule]

        init(rules: [any FallbackIsolationMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackIsolationMetric) -> [String] {
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

        func requireValid(_ item: FallbackIsolationMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackIsolationMetric]) -> [String: [String]] {
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

    static func defaultFallbackIsolationMetricValidator() -> FallbackIsolationMetricValidator {
        return FallbackIsolationMetricValidator(
            rules: [
                FallbackIsolationMetricCodePrefixRule(prefix: "ACM"),
                FallbackIsolationMetricPayerLengthRule(maxLength: 1000),
                FallbackIsolationMetricCodeLengthRule(maxLength: 80),
            ]
        )
    }
}

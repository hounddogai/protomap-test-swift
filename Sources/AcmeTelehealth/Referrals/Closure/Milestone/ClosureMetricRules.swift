import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure metric must pass. Check returns its problems, or none.
    protocol ClosureMetricRule {
        func check(_ item: ClosureMetric) -> [String]
    }

    final class ClosureMetricCodeLengthRule: ClosureMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureMetricRetriesRangeRule: ClosureMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureMetric) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClosureMetricRequiredCodeRule: ClosureMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureMetricCodePrefixRule: ClosureMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureMetricSourceLengthRule: ClosureMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureMetric) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureMetricAllowedTitleRule: ClosureMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a closure metric.
    final class ClosureMetricValidator {
        var rules: [any ClosureMetricRule]

        init(rules: [any ClosureMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureMetric]) -> [String: [String]] {
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

    static func defaultClosureMetricValidator() -> ClosureMetricValidator {
        return ClosureMetricValidator(
            rules: [
                ClosureMetricCodeLengthRule(maxLength: 64),
                ClosureMetricRetriesRangeRule(min: 16, max: 3600),
                ClosureMetricRequiredCodeRule(message: "closure metric needs a value"),
                ClosureMetricCodePrefixRule(prefix: "OPS"),
                ClosureMetricSourceLengthRule(maxLength: 64),
                ClosureMetricAllowedTitleRule(allowed: ["seasonal", "legacy"]),
            ]
        )
    }
}

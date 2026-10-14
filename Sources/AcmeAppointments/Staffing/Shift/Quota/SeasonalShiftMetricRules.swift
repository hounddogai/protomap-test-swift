import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal shift metric must pass. Check returns its problems, or none.
    protocol SeasonalShiftMetricRule {
        func check(_ item: SeasonalShiftMetric) -> [String]
    }

    final class SeasonalShiftMetricSequenceRangeRule: SeasonalShiftMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalShiftMetric) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalShiftMetricCodeLengthRule: SeasonalShiftMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalShiftMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalShiftMetricAllowedTitleRule: SeasonalShiftMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalShiftMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class SeasonalShiftMetricCodePrefixRule: SeasonalShiftMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalShiftMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalShiftMetricRequiredCodeRule: SeasonalShiftMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalShiftMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal shift metric.
    final class SeasonalShiftMetricValidator {
        var rules: [any SeasonalShiftMetricRule]

        init(rules: [any SeasonalShiftMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalShiftMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalShiftMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalShiftMetric]) -> [String: [String]] {
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

    static func defaultSeasonalShiftMetricValidator() -> SeasonalShiftMetricValidator {
        return SeasonalShiftMetricValidator(
            rules: [
                SeasonalShiftMetricSequenceRangeRule(min: 16, max: 32),
                SeasonalShiftMetricCodeLengthRule(maxLength: 32),
                SeasonalShiftMetricAllowedTitleRule(allowed: []),
                SeasonalShiftMetricCodePrefixRule(prefix: "X"),
                SeasonalShiftMetricRequiredCodeRule(message: "seasonal shift metric needs this field"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global recall summary must pass. Check returns its problems, or none.
    protocol GlobalRecallSummaryRule {
        func check(_ item: GlobalRecallSummary) -> [String]
    }

    final class GlobalRecallSummaryAmountRangeRule: GlobalRecallSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRecallSummary) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalRecallSummaryAllowedTitleRule: GlobalRecallSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalRecallSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class GlobalRecallSummaryCodePrefixRule: GlobalRecallSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalRecallSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalRecallSummarySummaryLengthRule: GlobalRecallSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRecallSummary) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRecallSummaryMaximumRangeRule: GlobalRecallSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRecallSummary) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global recall summary.
    final class GlobalRecallSummaryValidator {
        var rules: [any GlobalRecallSummaryRule]

        init(rules: [any GlobalRecallSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRecallSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalRecallSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRecallSummary]) -> [String: [String]] {
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

    static func defaultGlobalRecallSummaryValidator() -> GlobalRecallSummaryValidator {
        return GlobalRecallSummaryValidator(
            rules: [
                GlobalRecallSummaryAmountRangeRule(min: 8.6, max: 399.1),
                GlobalRecallSummaryAllowedTitleRule(allowed: ["tiered"]),
                GlobalRecallSummaryCodePrefixRule(prefix: "OPS"),
                GlobalRecallSummarySummaryLengthRule(maxLength: 64),
                GlobalRecallSummaryMaximumRangeRule(min: 4.4, max: 2733.6),
            ]
        )
    }
}

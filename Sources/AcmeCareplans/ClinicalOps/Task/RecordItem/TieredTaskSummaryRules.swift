import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered task summary must pass. Check returns its problems, or none.
    protocol TieredTaskSummaryRule {
        func check(_ item: TieredTaskSummary) -> [String]
    }

    final class TieredTaskSummaryCountryLengthRule: TieredTaskSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTaskSummary) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredTaskSummaryRequiredTitleRule: TieredTaskSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTaskSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTaskSummaryCostRangeRule: TieredTaskSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredTaskSummary) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered task summary.
    final class TieredTaskSummaryValidator {
        var rules: [any TieredTaskSummaryRule]

        init(rules: [any TieredTaskSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredTaskSummary) -> [String] {
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

        func requireValid(_ item: TieredTaskSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredTaskSummary]) -> [String: [String]] {
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

    static func defaultTieredTaskSummaryValidator() -> TieredTaskSummaryValidator {
        return TieredTaskSummaryValidator(
            rules: [
                TieredTaskSummaryCountryLengthRule(maxLength: 64),
                TieredTaskSummaryRequiredTitleRule(message: "tiered task summary needs an entry"),
                TieredTaskSummaryCostRangeRule(min: 10.0, max: 3349.4),
            ]
        )
    }
}

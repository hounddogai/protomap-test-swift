import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered follow up batch must pass. Check returns its problems, or none.
    protocol TieredFollowUpBatchRule {
        func check(_ item: TieredFollowUpBatch) -> [String]
    }

    final class TieredFollowUpBatchRequiredCodeRule: TieredFollowUpBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFollowUpBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFollowUpBatchRequiredTitleRule: TieredFollowUpBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFollowUpBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFollowUpBatchMinimumRangeRule: TieredFollowUpBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredFollowUpBatch) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered follow up batch.
    final class TieredFollowUpBatchValidator {
        var rules: [any TieredFollowUpBatchRule]

        init(rules: [any TieredFollowUpBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredFollowUpBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredFollowUpBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredFollowUpBatch]) -> [String: [String]] {
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

    static func defaultTieredFollowUpBatchValidator() -> TieredFollowUpBatchValidator {
        return TieredFollowUpBatchValidator(
            rules: [
                TieredFollowUpBatchRequiredCodeRule(message: "tiered follow up batch needs this field"),
                TieredFollowUpBatchRequiredTitleRule(message: "tiered follow up batch needs a value"),
                TieredFollowUpBatchMinimumRangeRule(min: 2.9, max: 856.6),
            ]
        )
    }
}

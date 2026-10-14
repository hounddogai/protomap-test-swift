import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered follow up baseline must pass. Check returns its problems, or none.
    protocol TieredFollowUpBaselineRule {
        func check(_ item: TieredFollowUpBaseline) -> [String]
    }

    final class TieredFollowUpBaselineRequiredTitleRule: TieredFollowUpBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFollowUpBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFollowUpBaselineBatchSizeRangeRule: TieredFollowUpBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredFollowUpBaseline) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredFollowUpBaselineSpecialtyLengthRule: TieredFollowUpBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredFollowUpBaseline) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredFollowUpBaselineTitleLengthRule: TieredFollowUpBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredFollowUpBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered follow up baseline.
    final class TieredFollowUpBaselineValidator {
        var rules: [any TieredFollowUpBaselineRule]

        init(rules: [any TieredFollowUpBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredFollowUpBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredFollowUpBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredFollowUpBaseline]) -> [String: [String]] {
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

    static func defaultTieredFollowUpBaselineValidator() -> TieredFollowUpBaselineValidator {
        return TieredFollowUpBaselineValidator(
            rules: [
                TieredFollowUpBaselineRequiredTitleRule(message: "tiered follow up baseline needs this field"),
                TieredFollowUpBaselineBatchSizeRangeRule(min: 32, max: 3600),
                TieredFollowUpBaselineSpecialtyLengthRule(maxLength: 86400),
                TieredFollowUpBaselineTitleLengthRule(maxLength: 120),
            ]
        )
    }
}

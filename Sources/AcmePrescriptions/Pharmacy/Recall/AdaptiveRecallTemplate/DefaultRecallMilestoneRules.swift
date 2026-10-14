import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default recall milestone must pass. Check returns its problems, or none.
    protocol DefaultRecallMilestoneRule {
        func check(_ item: DefaultRecallMilestone) -> [String]
    }

    final class DefaultRecallMilestoneCodeLengthRule: DefaultRecallMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRecallMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRecallMilestoneTitleLengthRule: DefaultRecallMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRecallMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRecallMilestoneQuantityRangeRule: DefaultRecallMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRecallMilestone) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultRecallMilestoneScoreRangeRule: DefaultRecallMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRecallMilestone) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default recall milestone.
    final class DefaultRecallMilestoneValidator {
        var rules: [any DefaultRecallMilestoneRule]

        init(rules: [any DefaultRecallMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRecallMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRecallMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRecallMilestone]) -> [String: [String]] {
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

    static func defaultDefaultRecallMilestoneValidator() -> DefaultRecallMilestoneValidator {
        return DefaultRecallMilestoneValidator(
            rules: [
                DefaultRecallMilestoneCodeLengthRule(maxLength: 86400),
                DefaultRecallMilestoneTitleLengthRule(maxLength: 64),
                DefaultRecallMilestoneQuantityRangeRule(min: 1000, max: 86400),
                DefaultRecallMilestoneScoreRangeRule(min: 4.9, max: 1833.7),
            ]
        )
    }
}

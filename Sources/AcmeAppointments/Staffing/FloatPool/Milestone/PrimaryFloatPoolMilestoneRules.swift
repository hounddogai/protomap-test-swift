import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary float pool milestone must pass. Check returns its problems, or none.
    protocol PrimaryFloatPoolMilestoneRule {
        func check(_ item: PrimaryFloatPoolMilestone) -> [String]
    }

    final class PrimaryFloatPoolMilestoneCodeLengthRule: PrimaryFloatPoolMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFloatPoolMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryFloatPoolMilestoneReviewerLengthRule: PrimaryFloatPoolMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFloatPoolMilestone) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryFloatPoolMilestoneRefillsRangeRule: PrimaryFloatPoolMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryFloatPoolMilestone) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryFloatPoolMilestoneRateRangeRule: PrimaryFloatPoolMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryFloatPoolMilestone) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary float pool milestone.
    final class PrimaryFloatPoolMilestoneValidator {
        var rules: [any PrimaryFloatPoolMilestoneRule]

        init(rules: [any PrimaryFloatPoolMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryFloatPoolMilestone) -> [String] {
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

        func requireValid(_ item: PrimaryFloatPoolMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryFloatPoolMilestone]) -> [String: [String]] {
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

    static func defaultPrimaryFloatPoolMilestoneValidator() -> PrimaryFloatPoolMilestoneValidator {
        return PrimaryFloatPoolMilestoneValidator(
            rules: [
                PrimaryFloatPoolMilestoneCodeLengthRule(maxLength: 255),
                PrimaryFloatPoolMilestoneReviewerLengthRule(maxLength: 16),
                PrimaryFloatPoolMilestoneRefillsRangeRule(min: 1000, max: 3600),
                PrimaryFloatPoolMilestoneRateRangeRule(min: 6.0, max: 2251.1),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted revocation milestone must pass. Check returns its problems, or none.
    protocol WeightedRevocationMilestoneRule {
        func check(_ item: WeightedRevocationMilestone) -> [String]
    }

    final class WeightedRevocationMilestoneCodeLengthRule: WeightedRevocationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRevocationMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRevocationMilestoneThresholdRangeRule: WeightedRevocationMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRevocationMilestone) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedRevocationMilestoneTitleLengthRule: WeightedRevocationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRevocationMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRevocationMilestoneWeightRangeRule: WeightedRevocationMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRevocationMilestone) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedRevocationMilestoneCodePrefixRule: WeightedRevocationMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedRevocationMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedRevocationMilestoneWardLengthRule: WeightedRevocationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRevocationMilestone) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted revocation milestone.
    final class WeightedRevocationMilestoneValidator {
        var rules: [any WeightedRevocationMilestoneRule]

        init(rules: [any WeightedRevocationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRevocationMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedRevocationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRevocationMilestone]) -> [String: [String]] {
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

    static func defaultWeightedRevocationMilestoneValidator() -> WeightedRevocationMilestoneValidator {
        return WeightedRevocationMilestoneValidator(
            rules: [
                WeightedRevocationMilestoneCodeLengthRule(maxLength: 120),
                WeightedRevocationMilestoneThresholdRangeRule(min: 1.5, max: 266.3),
                WeightedRevocationMilestoneTitleLengthRule(maxLength: 120),
                WeightedRevocationMilestoneWeightRangeRule(min: 2.1, max: 2720.3),
                WeightedRevocationMilestoneCodePrefixRule(prefix: "Q"),
                WeightedRevocationMilestoneWardLengthRule(maxLength: 120),
            ]
        )
    }
}

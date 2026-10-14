import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default courier milestone must pass. Check returns its problems, or none.
    protocol DefaultCourierMilestoneRule {
        func check(_ item: DefaultCourierMilestone) -> [String]
    }

    final class DefaultCourierMilestoneWeightRangeRule: DefaultCourierMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCourierMilestone) -> [String] {
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

    final class DefaultCourierMilestoneFloorValueRangeRule: DefaultCourierMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCourierMilestone) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCourierMilestoneCodeLengthRule: DefaultCourierMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCourierMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default courier milestone.
    final class DefaultCourierMilestoneValidator {
        var rules: [any DefaultCourierMilestoneRule]

        init(rules: [any DefaultCourierMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCourierMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCourierMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCourierMilestone]) -> [String: [String]] {
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

    static func defaultDefaultCourierMilestoneValidator() -> DefaultCourierMilestoneValidator {
        return DefaultCourierMilestoneValidator(
            rules: [
                DefaultCourierMilestoneWeightRangeRule(min: 4.3, max: 1595.0),
                DefaultCourierMilestoneFloorValueRangeRule(min: 9.6, max: 2274.9),
                DefaultCourierMilestoneCodeLengthRule(maxLength: 255),
            ]
        )
    }
}

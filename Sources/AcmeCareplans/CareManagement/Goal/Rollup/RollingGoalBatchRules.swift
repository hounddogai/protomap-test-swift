import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling goal batch must pass. Check returns its problems, or none.
    protocol RollingGoalBatchRule {
        func check(_ item: RollingGoalBatch) -> [String]
    }

    final class RollingGoalBatchNameLengthRule: RollingGoalBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingGoalBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingGoalBatchRequiredTitleRule: RollingGoalBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingGoalBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingGoalBatchAllowedUnitRule: RollingGoalBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingGoalBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is above maximum"]
            }
            return []
        }
    }

    final class RollingGoalBatchAmountRangeRule: RollingGoalBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingGoalBatch) -> [String] {
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

    final class RollingGoalBatchTitleLengthRule: RollingGoalBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingGoalBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingGoalBatchRequiredNameRule: RollingGoalBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingGoalBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling goal batch.
    final class RollingGoalBatchValidator {
        var rules: [any RollingGoalBatchRule]

        init(rules: [any RollingGoalBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingGoalBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingGoalBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingGoalBatch]) -> [String: [String]] {
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

    static func defaultRollingGoalBatchValidator() -> RollingGoalBatchValidator {
        return RollingGoalBatchValidator(
            rules: [
                RollingGoalBatchNameLengthRule(maxLength: 64),
                RollingGoalBatchRequiredTitleRule(message: "rolling goal batch needs an entry"),
                RollingGoalBatchAllowedUnitRule(allowed: ["weighted"]),
                RollingGoalBatchAmountRangeRule(min: 7.6, max: 2847.0),
                RollingGoalBatchTitleLengthRule(maxLength: 80),
                RollingGoalBatchRequiredNameRule(message: "rolling goal batch needs a value"),
            ]
        )
    }
}

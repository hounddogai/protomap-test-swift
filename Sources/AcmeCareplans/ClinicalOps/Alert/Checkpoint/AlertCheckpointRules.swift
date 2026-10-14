import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert checkpoint must pass. Check returns its problems, or none.
    protocol AlertCheckpointRule {
        func check(_ item: AlertCheckpoint) -> [String]
    }

    final class AlertCheckpointCostRangeRule: AlertCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertCheckpoint) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AlertCheckpointLimitRangeRule: AlertCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertCheckpoint) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AlertCheckpointEndsAtRangeRule: AlertCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertCheckpoint) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertCheckpointRequiredNameRule: AlertCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertCheckpointCodeLengthRule: AlertCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert checkpoint.
    final class AlertCheckpointValidator {
        var rules: [any AlertCheckpointRule]

        init(rules: [any AlertCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertCheckpoint]) -> [String: [String]] {
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

    static func defaultAlertCheckpointValidator() -> AlertCheckpointValidator {
        return AlertCheckpointValidator(
            rules: [
                AlertCheckpointCostRangeRule(min: 0.1, max: 2328.5),
                AlertCheckpointLimitRangeRule(min: 80, max: 1000),
                AlertCheckpointEndsAtRangeRule(min: 120, max: 3600),
                AlertCheckpointRequiredNameRule(message: "alert checkpoint needs a value"),
                AlertCheckpointCodeLengthRule(maxLength: 32),
            ]
        )
    }
}

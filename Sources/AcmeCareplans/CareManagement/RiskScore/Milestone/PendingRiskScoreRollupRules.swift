import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending risk score rollup must pass. Check returns its problems, or none.
    protocol PendingRiskScoreRollupRule {
        func check(_ item: PendingRiskScoreRollup) -> [String]
    }

    final class PendingRiskScoreRollupNameLengthRule: PendingRiskScoreRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRiskScoreRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRiskScoreRollupRequiredCodeRule: PendingRiskScoreRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRiskScoreRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRiskScoreRollupMaximumRangeRule: PendingRiskScoreRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRiskScoreRollup) -> [String] {
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

    final class PendingRiskScoreRollupCodeLengthRule: PendingRiskScoreRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRiskScoreRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRiskScoreRollupQuantityRangeRule: PendingRiskScoreRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRiskScoreRollup) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending risk score rollup.
    final class PendingRiskScoreRollupValidator {
        var rules: [any PendingRiskScoreRollupRule]

        init(rules: [any PendingRiskScoreRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRiskScoreRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingRiskScoreRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRiskScoreRollup]) -> [String: [String]] {
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

    static func defaultPendingRiskScoreRollupValidator() -> PendingRiskScoreRollupValidator {
        return PendingRiskScoreRollupValidator(
            rules: [
                PendingRiskScoreRollupNameLengthRule(maxLength: 64),
                PendingRiskScoreRollupRequiredCodeRule(message: "pending risk score rollup needs an entry"),
                PendingRiskScoreRollupMaximumRangeRule(min: 4.7, max: 3577.9),
                PendingRiskScoreRollupCodeLengthRule(maxLength: 16),
                PendingRiskScoreRollupQuantityRangeRule(min: 32, max: 32),
            ]
        )
    }
}

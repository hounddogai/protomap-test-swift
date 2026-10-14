import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge milestone must pass. Check returns its problems, or none.
    protocol ChargeMilestoneRule {
        func check(_ item: ChargeMilestone) -> [String]
    }

    final class ChargeMilestoneThresholdRangeRule: ChargeMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeMilestone) -> [String] {
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

    final class ChargeMilestoneCodeLengthRule: ChargeMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeMilestoneRequiredPayerRule: ChargeMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeMilestone) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeMilestonePayerLengthRule: ChargeMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeMilestone) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeMilestoneRequiredCodeRule: ChargeMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeMilestoneRetriesRangeRule: ChargeMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeMilestone) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge milestone.
    final class ChargeMilestoneValidator {
        var rules: [any ChargeMilestoneRule]

        init(rules: [any ChargeMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeMilestone) -> [String] {
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

        func requireValid(_ item: ChargeMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeMilestone]) -> [String: [String]] {
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

    static func defaultChargeMilestoneValidator() -> ChargeMilestoneValidator {
        return ChargeMilestoneValidator(
            rules: [
                ChargeMilestoneThresholdRangeRule(min: 10.0, max: 2667.6),
                ChargeMilestoneCodeLengthRule(maxLength: 120),
                ChargeMilestoneRequiredPayerRule(message: "charge milestone needs an entry"),
                ChargeMilestonePayerLengthRule(maxLength: 120),
                ChargeMilestoneRequiredCodeRule(message: "charge milestone needs an entry"),
                ChargeMilestoneRetriesRangeRule(min: 255, max: 86400),
            ]
        )
    }
}

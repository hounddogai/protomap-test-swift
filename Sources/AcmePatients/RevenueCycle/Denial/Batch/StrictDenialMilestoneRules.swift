import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict denial milestone must pass. Check returns its problems, or none.
    protocol StrictDenialMilestoneRule {
        func check(_ item: StrictDenialMilestone) -> [String]
    }

    final class StrictDenialMilestoneTitleLengthRule: StrictDenialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDenialMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictDenialMilestoneRequiredCurrencyRule: StrictDenialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictDenialMilestone) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictDenialMilestoneExpiresAtRangeRule: StrictDenialMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictDenialMilestone) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictDenialMilestoneCodeLengthRule: StrictDenialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDenialMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict denial milestone.
    final class StrictDenialMilestoneValidator {
        var rules: [any StrictDenialMilestoneRule]

        init(rules: [any StrictDenialMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictDenialMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictDenialMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictDenialMilestone]) -> [String: [String]] {
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

    static func defaultStrictDenialMilestoneValidator() -> StrictDenialMilestoneValidator {
        return StrictDenialMilestoneValidator(
            rules: [
                StrictDenialMilestoneTitleLengthRule(maxLength: 255),
                StrictDenialMilestoneRequiredCurrencyRule(message: "strict denial milestone needs a value"),
                StrictDenialMilestoneExpiresAtRangeRule(min: 255, max: 1000),
                StrictDenialMilestoneCodeLengthRule(maxLength: 80),
            ]
        )
    }
}

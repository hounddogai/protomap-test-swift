import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility target must pass. Check returns its problems, or none.
    protocol EligibilityTargetRule {
        func check(_ item: EligibilityTarget) -> [String]
    }

    final class EligibilityTargetNameLengthRule: EligibilityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityTargetDurationMinutesRangeRule: EligibilityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityTarget) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityTargetRequiredCodeRule: EligibilityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityTargetRequiredTitleRule: EligibilityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityTargetEndsAtRangeRule: EligibilityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityTarget) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility target.
    final class EligibilityTargetValidator {
        var rules: [any EligibilityTargetRule]

        init(rules: [any EligibilityTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityTarget) -> [String] {
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

        func requireValid(_ item: EligibilityTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityTarget]) -> [String: [String]] {
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

    static func defaultEligibilityTargetValidator() -> EligibilityTargetValidator {
        return EligibilityTargetValidator(
            rules: [
                EligibilityTargetNameLengthRule(maxLength: 255),
                EligibilityTargetDurationMinutesRangeRule(min: 16, max: 86400),
                EligibilityTargetRequiredCodeRule(message: "eligibility target needs an entry"),
                EligibilityTargetRequiredTitleRule(message: "eligibility target needs this field"),
                EligibilityTargetEndsAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}

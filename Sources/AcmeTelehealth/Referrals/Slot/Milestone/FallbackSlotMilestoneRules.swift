import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback slot milestone must pass. Check returns its problems, or none.
    protocol FallbackSlotMilestoneRule {
        func check(_ item: FallbackSlotMilestone) -> [String]
    }

    final class FallbackSlotMilestoneNameLengthRule: FallbackSlotMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSlotMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSlotMilestoneTimezoneLengthRule: FallbackSlotMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSlotMilestone) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSlotMilestoneRequiredNameRule: FallbackSlotMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackSlotMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback slot milestone.
    final class FallbackSlotMilestoneValidator {
        var rules: [any FallbackSlotMilestoneRule]

        init(rules: [any FallbackSlotMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSlotMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackSlotMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSlotMilestone]) -> [String: [String]] {
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

    static func defaultFallbackSlotMilestoneValidator() -> FallbackSlotMilestoneValidator {
        return FallbackSlotMilestoneValidator(
            rules: [
                FallbackSlotMilestoneNameLengthRule(maxLength: 80),
                FallbackSlotMilestoneTimezoneLengthRule(maxLength: 80),
                FallbackSlotMilestoneRequiredNameRule(message: "fallback slot milestone needs an entry"),
            ]
        )
    }
}

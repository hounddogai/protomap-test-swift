import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial milestone must pass. Check returns its problems, or none.
    protocol DenialMilestoneRule {
        func check(_ item: DenialMilestone) -> [String]
    }

    final class DenialMilestoneAllowedContactEmailRule: DenialMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is inconsistent"]
            }
            return []
        }
    }

    final class DenialMilestoneUpdatedAtRangeRule: DenialMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialMilestone) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialMilestoneNotesLengthRule: DenialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialMilestone) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialMilestoneRequiredContactEmailRule: DenialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialMilestone) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialMilestoneContactEmailLengthRule: DenialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialMilestone) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialMilestoneRequiredCodeRule: DenialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial milestone.
    final class DenialMilestoneValidator {
        var rules: [any DenialMilestoneRule]

        init(rules: [any DenialMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialMilestone) -> [String] {
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

        func requireValid(_ item: DenialMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialMilestone]) -> [String: [String]] {
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

    static func defaultDenialMilestoneValidator() -> DenialMilestoneValidator {
        return DenialMilestoneValidator(
            rules: [
                DenialMilestoneAllowedContactEmailRule(allowed: ["legacy", "strict", "primary"]),
                DenialMilestoneUpdatedAtRangeRule(min: 64, max: 64),
                DenialMilestoneNotesLengthRule(maxLength: 1000),
                DenialMilestoneRequiredContactEmailRule(message: "denial milestone needs an entry"),
                DenialMilestoneContactEmailLengthRule(maxLength: 32),
                DenialMilestoneRequiredCodeRule(message: "denial milestone needs an entry"),
            ]
        )
    }
}

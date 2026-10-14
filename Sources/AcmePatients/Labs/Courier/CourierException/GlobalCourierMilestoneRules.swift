import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global courier milestone must pass. Check returns its problems, or none.
    protocol GlobalCourierMilestoneRule {
        func check(_ item: GlobalCourierMilestone) -> [String]
    }

    final class GlobalCourierMilestoneLabelLengthRule: GlobalCourierMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCourierMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCourierMilestoneRequiredTimezoneRule: GlobalCourierMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCourierMilestone) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCourierMilestoneRequiredCodeRule: GlobalCourierMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCourierMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCourierMilestoneRequiredLabelRule: GlobalCourierMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCourierMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global courier milestone.
    final class GlobalCourierMilestoneValidator {
        var rules: [any GlobalCourierMilestoneRule]

        init(rules: [any GlobalCourierMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCourierMilestone) -> [String] {
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

        func requireValid(_ item: GlobalCourierMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCourierMilestone]) -> [String: [String]] {
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

    static func defaultGlobalCourierMilestoneValidator() -> GlobalCourierMilestoneValidator {
        return GlobalCourierMilestoneValidator(
            rules: [
                GlobalCourierMilestoneLabelLengthRule(maxLength: 16),
                GlobalCourierMilestoneRequiredTimezoneRule(message: "global courier milestone needs a value"),
                GlobalCourierMilestoneRequiredCodeRule(message: "global courier milestone needs an entry"),
                GlobalCourierMilestoneRequiredLabelRule(message: "global courier milestone needs a value"),
            ]
        )
    }
}

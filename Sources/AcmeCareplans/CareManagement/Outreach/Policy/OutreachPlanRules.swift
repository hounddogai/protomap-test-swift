import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach plan must pass. Check returns its problems, or none.
    protocol OutreachPlanRule {
        func check(_ item: OutreachPlan) -> [String]
    }

    final class OutreachPlanRequiredNotesRule: OutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachPlan) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachPlanRequiredNameRule: OutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachPlanWindowDaysRangeRule: OutreachPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachPlan) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachPlanCodePrefixRule: OutreachPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach plan.
    final class OutreachPlanValidator {
        var rules: [any OutreachPlanRule]

        init(rules: [any OutreachPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachPlan]) -> [String: [String]] {
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

    static func defaultOutreachPlanValidator() -> OutreachPlanValidator {
        return OutreachPlanValidator(
            rules: [
                OutreachPlanRequiredNotesRule(message: "outreach plan needs a value"),
                OutreachPlanRequiredNameRule(message: "outreach plan needs an entry"),
                OutreachPlanWindowDaysRangeRule(min: 64, max: 86400),
                OutreachPlanCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}

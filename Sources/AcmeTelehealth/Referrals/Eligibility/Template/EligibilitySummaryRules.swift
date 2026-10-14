import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility summary must pass. Check returns its problems, or none.
    protocol EligibilitySummaryRule {
        func check(_ item: EligibilitySummary) -> [String]
    }

    final class EligibilitySummaryUpdatedAtRangeRule: EligibilitySummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilitySummary) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilitySummaryPriorityRangeRule: EligibilitySummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilitySummary) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilitySummaryRequiredNotesRule: EligibilitySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilitySummary) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilitySummaryRequiredTitleRule: EligibilitySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilitySummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilitySummaryAllowedNotesRule: EligibilitySummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilitySummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility summary.
    final class EligibilitySummaryValidator {
        var rules: [any EligibilitySummaryRule]

        init(rules: [any EligibilitySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilitySummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilitySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilitySummary]) -> [String: [String]] {
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

    static func defaultEligibilitySummaryValidator() -> EligibilitySummaryValidator {
        return EligibilitySummaryValidator(
            rules: [
                EligibilitySummaryUpdatedAtRangeRule(min: 16, max: 86400),
                EligibilitySummaryPriorityRangeRule(min: 80, max: 86400),
                EligibilitySummaryRequiredNotesRule(message: "eligibility summary needs an entry"),
                EligibilitySummaryRequiredTitleRule(message: "eligibility summary needs an entry"),
                EligibilitySummaryAllowedNotesRule(allowed: []),
            ]
        )
    }
}

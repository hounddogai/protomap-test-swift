import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach draft must pass. Check returns its problems, or none.
    protocol OutreachDraftRule {
        func check(_ item: OutreachDraft) -> [String]
    }

    final class OutreachDraftAllowedTitleRule: OutreachDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class OutreachDraftAmountRangeRule: OutreachDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachDraft) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachDraftRequiredTitleRule: OutreachDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach draft.
    final class OutreachDraftValidator {
        var rules: [any OutreachDraftRule]

        init(rules: [any OutreachDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachDraft) -> [String] {
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

        func requireValid(_ item: OutreachDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachDraft]) -> [String: [String]] {
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

    static func defaultOutreachDraftValidator() -> OutreachDraftValidator {
        return OutreachDraftValidator(
            rules: [
                OutreachDraftAllowedTitleRule(allowed: []),
                OutreachDraftAmountRangeRule(min: 8.6, max: 1284.8),
                OutreachDraftRequiredTitleRule(message: "outreach draft needs an entry"),
            ]
        )
    }
}

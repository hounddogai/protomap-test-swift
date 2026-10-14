import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending claim draft must pass. Check returns its problems, or none.
    protocol PendingClaimDraftRule {
        func check(_ item: PendingClaimDraft) -> [String]
    }

    final class PendingClaimDraftVisitMinutesRangeRule: PendingClaimDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimDraft) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingClaimDraftRequiredNameRule: PendingClaimDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingClaimDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingClaimDraftDosageMgRangeRule: PendingClaimDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimDraft) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingClaimDraftBudgetRangeRule: PendingClaimDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimDraft) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingClaimDraftRequiredLabelRule: PendingClaimDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingClaimDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending claim draft.
    final class PendingClaimDraftValidator {
        var rules: [any PendingClaimDraftRule]

        init(rules: [any PendingClaimDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingClaimDraft) -> [String] {
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

        func requireValid(_ item: PendingClaimDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingClaimDraft]) -> [String: [String]] {
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

    static func defaultPendingClaimDraftValidator() -> PendingClaimDraftValidator {
        return PendingClaimDraftValidator(
            rules: [
                PendingClaimDraftVisitMinutesRangeRule(min: 64, max: 3600),
                PendingClaimDraftRequiredNameRule(message: "pending claim draft needs a value"),
                PendingClaimDraftDosageMgRangeRule(min: 5.1, max: 1639.0),
                PendingClaimDraftBudgetRangeRule(min: 5.1, max: 3212.5),
                PendingClaimDraftRequiredLabelRule(message: "pending claim draft needs an entry"),
            ]
        )
    }
}

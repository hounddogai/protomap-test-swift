import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped network draft must pass. Check returns its problems, or none.
    protocol CappedNetworkDraftRule {
        func check(_ item: CappedNetworkDraft) -> [String]
    }

    final class CappedNetworkDraftRequiredReviewerRule: CappedNetworkDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedNetworkDraft) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedNetworkDraftReviewerLengthRule: CappedNetworkDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedNetworkDraft) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedNetworkDraftRequiredPatientRefRule: CappedNetworkDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedNetworkDraft) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedNetworkDraftBudgetRangeRule: CappedNetworkDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedNetworkDraft) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedNetworkDraftRequiredLabelRule: CappedNetworkDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedNetworkDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped network draft.
    final class CappedNetworkDraftValidator {
        var rules: [any CappedNetworkDraftRule]

        init(rules: [any CappedNetworkDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedNetworkDraft) -> [String] {
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

        func requireValid(_ item: CappedNetworkDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedNetworkDraft]) -> [String: [String]] {
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

    static func defaultCappedNetworkDraftValidator() -> CappedNetworkDraftValidator {
        return CappedNetworkDraftValidator(
            rules: [
                CappedNetworkDraftRequiredReviewerRule(message: "capped network draft needs an entry"),
                CappedNetworkDraftReviewerLengthRule(maxLength: 64),
                CappedNetworkDraftRequiredPatientRefRule(message: "capped network draft needs a value"),
                CappedNetworkDraftBudgetRangeRule(min: 4.0, max: 1388.5),
                CappedNetworkDraftRequiredLabelRule(message: "capped network draft needs an entry"),
            ]
        )
    }
}

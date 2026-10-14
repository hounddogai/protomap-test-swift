import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal goal draft must pass. Check returns its problems, or none.
    protocol SeasonalGoalDraftRule {
        func check(_ item: SeasonalGoalDraft) -> [String]
    }

    final class SeasonalGoalDraftUpdatedAtRangeRule: SeasonalGoalDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalGoalDraft) -> [String] {
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

    final class SeasonalGoalDraftRequiredPhoneRule: SeasonalGoalDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalGoalDraft) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalGoalDraftLabelLengthRule: SeasonalGoalDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalGoalDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalGoalDraftRequiredLabelRule: SeasonalGoalDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalGoalDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal goal draft.
    final class SeasonalGoalDraftValidator {
        var rules: [any SeasonalGoalDraftRule]

        init(rules: [any SeasonalGoalDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalGoalDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalGoalDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalGoalDraft]) -> [String: [String]] {
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

    static func defaultSeasonalGoalDraftValidator() -> SeasonalGoalDraftValidator {
        return SeasonalGoalDraftValidator(
            rules: [
                SeasonalGoalDraftUpdatedAtRangeRule(min: 16, max: 255),
                SeasonalGoalDraftRequiredPhoneRule(message: "seasonal goal draft needs this field"),
                SeasonalGoalDraftLabelLengthRule(maxLength: 64),
                SeasonalGoalDraftRequiredLabelRule(message: "seasonal goal draft needs an entry"),
            ]
        )
    }
}

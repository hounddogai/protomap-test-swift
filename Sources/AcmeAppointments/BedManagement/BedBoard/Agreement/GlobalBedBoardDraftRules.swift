import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global bed board draft must pass. Check returns its problems, or none.
    protocol GlobalBedBoardDraftRule {
        func check(_ item: GlobalBedBoardDraft) -> [String]
    }

    final class GlobalBedBoardDraftRequiredLabelRule: GlobalBedBoardDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalBedBoardDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalBedBoardDraftRequiredAllergyRule: GlobalBedBoardDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalBedBoardDraft) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalBedBoardDraftRatioRangeRule: GlobalBedBoardDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalBedBoardDraft) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global bed board draft.
    final class GlobalBedBoardDraftValidator {
        var rules: [any GlobalBedBoardDraftRule]

        init(rules: [any GlobalBedBoardDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalBedBoardDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalBedBoardDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalBedBoardDraft]) -> [String: [String]] {
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

    static func defaultGlobalBedBoardDraftValidator() -> GlobalBedBoardDraftValidator {
        return GlobalBedBoardDraftValidator(
            rules: [
                GlobalBedBoardDraftRequiredLabelRule(message: "global bed board draft needs an entry"),
                GlobalBedBoardDraftRequiredAllergyRule(message: "global bed board draft needs a value"),
                GlobalBedBoardDraftRatioRangeRule(min: 9.6, max: 4313.7),
            ]
        )
    }
}

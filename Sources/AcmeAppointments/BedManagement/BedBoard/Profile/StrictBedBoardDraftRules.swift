import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict bed board draft must pass. Check returns its problems, or none.
    protocol StrictBedBoardDraftRule {
        func check(_ item: StrictBedBoardDraft) -> [String]
    }

    final class StrictBedBoardDraftRequiredCodeRule: StrictBedBoardDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictBedBoardDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictBedBoardDraftAllowedCategoryRule: StrictBedBoardDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictBedBoardDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is unknown"]
            }
            return []
        }
    }

    final class StrictBedBoardDraftRequiredCountryRule: StrictBedBoardDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictBedBoardDraft) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictBedBoardDraftCodeLengthRule: StrictBedBoardDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictBedBoardDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictBedBoardDraftLabelLengthRule: StrictBedBoardDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictBedBoardDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict bed board draft.
    final class StrictBedBoardDraftValidator {
        var rules: [any StrictBedBoardDraftRule]

        init(rules: [any StrictBedBoardDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictBedBoardDraft) -> [String] {
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

        func requireValid(_ item: StrictBedBoardDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictBedBoardDraft]) -> [String: [String]] {
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

    static func defaultStrictBedBoardDraftValidator() -> StrictBedBoardDraftValidator {
        return StrictBedBoardDraftValidator(
            rules: [
                StrictBedBoardDraftRequiredCodeRule(message: "strict bed board draft needs an entry"),
                StrictBedBoardDraftAllowedCategoryRule(allowed: ["legacy", "scheduled"]),
                StrictBedBoardDraftRequiredCountryRule(message: "strict bed board draft needs this field"),
                StrictBedBoardDraftCodeLengthRule(maxLength: 1000),
                StrictBedBoardDraftLabelLengthRule(maxLength: 120),
            ]
        )
    }
}

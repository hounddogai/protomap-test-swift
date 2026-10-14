import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual census draft must pass. Check returns its problems, or none.
    protocol ManualCensusDraftRule {
        func check(_ item: ManualCensusDraft) -> [String]
    }

    final class ManualCensusDraftCodeLengthRule: ManualCensusDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCensusDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCensusDraftRequiredCodeRule: ManualCensusDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCensusDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCensusDraftRequiredLabelRule: ManualCensusDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCensusDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCensusDraftRequiredNotesRule: ManualCensusDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCensusDraft) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual census draft.
    final class ManualCensusDraftValidator {
        var rules: [any ManualCensusDraftRule]

        init(rules: [any ManualCensusDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCensusDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCensusDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCensusDraft]) -> [String: [String]] {
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

    static func defaultManualCensusDraftValidator() -> ManualCensusDraftValidator {
        return ManualCensusDraftValidator(
            rules: [
                ManualCensusDraftCodeLengthRule(maxLength: 120),
                ManualCensusDraftRequiredCodeRule(message: "manual census draft needs this field"),
                ManualCensusDraftRequiredLabelRule(message: "manual census draft needs this field"),
                ManualCensusDraftRequiredNotesRule(message: "manual census draft needs an entry"),
            ]
        )
    }
}

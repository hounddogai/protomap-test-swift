import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift draft must pass. Check returns its problems, or none.
    protocol ShiftDraftRule {
        func check(_ item: ShiftDraft) -> [String]
    }

    final class ShiftDraftCodeLengthRule: ShiftDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftDraftRequiredCodeRule: ShiftDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftDraftRequiredUnitRule: ShiftDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftDraft) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift draft.
    final class ShiftDraftValidator {
        var rules: [any ShiftDraftRule]

        init(rules: [any ShiftDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftDraft) -> [String] {
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

        func requireValid(_ item: ShiftDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftDraft]) -> [String: [String]] {
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

    static func defaultShiftDraftValidator() -> ShiftDraftValidator {
        return ShiftDraftValidator(
            rules: [
                ShiftDraftCodeLengthRule(maxLength: 80),
                ShiftDraftRequiredCodeRule(message: "shift draft needs an entry"),
                ShiftDraftRequiredUnitRule(message: "shift draft needs an entry"),
            ]
        )
    }
}

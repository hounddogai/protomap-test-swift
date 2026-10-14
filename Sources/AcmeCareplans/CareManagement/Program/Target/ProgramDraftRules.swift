import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program draft must pass. Check returns its problems, or none.
    protocol ProgramDraftRule {
        func check(_ item: ProgramDraft) -> [String]
    }

    final class ProgramDraftRequiredTitleRule: ProgramDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramDraftCodeLengthRule: ProgramDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramDraftTitleLengthRule: ProgramDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramDraftRequiredPhoneRule: ProgramDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramDraft) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program draft.
    final class ProgramDraftValidator {
        var rules: [any ProgramDraftRule]

        init(rules: [any ProgramDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramDraft]) -> [String: [String]] {
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

    static func defaultProgramDraftValidator() -> ProgramDraftValidator {
        return ProgramDraftValidator(
            rules: [
                ProgramDraftRequiredTitleRule(message: "program draft needs this field"),
                ProgramDraftCodeLengthRule(maxLength: 1000),
                ProgramDraftTitleLengthRule(maxLength: 255),
                ProgramDraftRequiredPhoneRule(message: "program draft needs a value"),
            ]
        )
    }
}

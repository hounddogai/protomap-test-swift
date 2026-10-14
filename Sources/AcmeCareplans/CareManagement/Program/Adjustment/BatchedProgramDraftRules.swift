import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched program draft must pass. Check returns its problems, or none.
    protocol BatchedProgramDraftRule {
        func check(_ item: BatchedProgramDraft) -> [String]
    }

    final class BatchedProgramDraftExternalRefLengthRule: BatchedProgramDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProgramDraft) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProgramDraftNotesLengthRule: BatchedProgramDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProgramDraft) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProgramDraftRequiredExternalRefRule: BatchedProgramDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProgramDraft) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedProgramDraftTitleLengthRule: BatchedProgramDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProgramDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched program draft.
    final class BatchedProgramDraftValidator {
        var rules: [any BatchedProgramDraftRule]

        init(rules: [any BatchedProgramDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProgramDraft) -> [String] {
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

        func requireValid(_ item: BatchedProgramDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProgramDraft]) -> [String: [String]] {
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

    static func defaultBatchedProgramDraftValidator() -> BatchedProgramDraftValidator {
        return BatchedProgramDraftValidator(
            rules: [
                BatchedProgramDraftExternalRefLengthRule(maxLength: 120),
                BatchedProgramDraftNotesLengthRule(maxLength: 86400),
                BatchedProgramDraftRequiredExternalRefRule(message: "batched program draft needs a value"),
                BatchedProgramDraftTitleLengthRule(maxLength: 32),
            ]
        )
    }
}

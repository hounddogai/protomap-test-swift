import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending priority draft must pass. Check returns its problems, or none.
    protocol PendingPriorityDraftRule {
        func check(_ item: PendingPriorityDraft) -> [String]
    }

    final class PendingPriorityDraftCodeLengthRule: PendingPriorityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingPriorityDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingPriorityDraftProcedureCodeLengthRule: PendingPriorityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingPriorityDraft) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingPriorityDraftRequiredProcedureCodeRule: PendingPriorityDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingPriorityDraft) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending priority draft.
    final class PendingPriorityDraftValidator {
        var rules: [any PendingPriorityDraftRule]

        init(rules: [any PendingPriorityDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingPriorityDraft) -> [String] {
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

        func requireValid(_ item: PendingPriorityDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingPriorityDraft]) -> [String: [String]] {
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

    static func defaultPendingPriorityDraftValidator() -> PendingPriorityDraftValidator {
        return PendingPriorityDraftValidator(
            rules: [
                PendingPriorityDraftCodeLengthRule(maxLength: 1000),
                PendingPriorityDraftProcedureCodeLengthRule(maxLength: 255),
                PendingPriorityDraftRequiredProcedureCodeRule(message: "pending priority draft needs a value"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall draft must pass. Check returns its problems, or none.
    protocol RecallDraftRule {
        func check(_ item: RecallDraft) -> [String]
    }

    final class RecallDraftRequiredDescriptionRule: RecallDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallDraft) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallDraftArchivedGuardRule: RecallDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RecallDraft) -> [String] {
            if item.archived && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RecallDraftAllowedTitleRule: RecallDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class RecallDraftDescriptionLengthRule: RecallDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallDraft) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall draft.
    final class RecallDraftValidator {
        var rules: [any RecallDraftRule]

        init(rules: [any RecallDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallDraft) -> [String] {
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

        func requireValid(_ item: RecallDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallDraft]) -> [String: [String]] {
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

    static func defaultRecallDraftValidator() -> RecallDraftValidator {
        return RecallDraftValidator(
            rules: [
                RecallDraftRequiredDescriptionRule(message: "recall draft needs a value"),
                RecallDraftArchivedGuardRule(limit: 120),
                RecallDraftAllowedTitleRule(allowed: ["scheduled", "primary"]),
                RecallDraftDescriptionLengthRule(maxLength: 32),
            ]
        )
    }
}

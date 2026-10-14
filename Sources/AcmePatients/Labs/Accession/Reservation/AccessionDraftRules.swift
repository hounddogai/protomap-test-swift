import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession draft must pass. Check returns its problems, or none.
    protocol AccessionDraftRule {
        func check(_ item: AccessionDraft) -> [String]
    }

    final class AccessionDraftRequiredNameRule: AccessionDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionDraftAllowedCodeRule: AccessionDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class AccessionDraftNameLengthRule: AccessionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionDraftCreatedAtRangeRule: AccessionDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionDraft) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionDraftCodeLengthRule: AccessionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession draft.
    final class AccessionDraftValidator {
        var rules: [any AccessionDraftRule]

        init(rules: [any AccessionDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionDraft) -> [String] {
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

        func requireValid(_ item: AccessionDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionDraft]) -> [String: [String]] {
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

    static func defaultAccessionDraftValidator() -> AccessionDraftValidator {
        return AccessionDraftValidator(
            rules: [
                AccessionDraftRequiredNameRule(message: "accession draft needs an entry"),
                AccessionDraftAllowedCodeRule(allowed: []),
                AccessionDraftNameLengthRule(maxLength: 32),
                AccessionDraftCreatedAtRangeRule(min: 120, max: 255),
                AccessionDraftCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

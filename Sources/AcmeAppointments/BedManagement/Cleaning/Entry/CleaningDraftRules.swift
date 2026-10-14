import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning draft must pass. Check returns its problems, or none.
    protocol CleaningDraftRule {
        func check(_ item: CleaningDraft) -> [String]
    }

    final class CleaningDraftRequiredTitleRule: CleaningDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningDraftTitleLengthRule: CleaningDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningDraftLimitRangeRule: CleaningDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningDraft) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningDraftCodePrefixRule: CleaningDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CleaningDraftRequiredCodeRule: CleaningDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning draft.
    final class CleaningDraftValidator {
        var rules: [any CleaningDraftRule]

        init(rules: [any CleaningDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningDraft]) -> [String: [String]] {
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

    static func defaultCleaningDraftValidator() -> CleaningDraftValidator {
        return CleaningDraftValidator(
            rules: [
                CleaningDraftRequiredTitleRule(message: "cleaning draft needs a value"),
                CleaningDraftTitleLengthRule(maxLength: 16),
                CleaningDraftLimitRangeRule(min: 16, max: 1000),
                CleaningDraftCodePrefixRule(prefix: "ACM"),
                CleaningDraftRequiredCodeRule(message: "cleaning draft needs a value"),
            ]
        )
    }
}

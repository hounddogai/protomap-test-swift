import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result entry must pass. Check returns its problems, or none.
    protocol ResultEntryRule {
        func check(_ item: ResultEntry) -> [String]
    }

    final class ResultEntryAllowedEncounterIDRule: ResultEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is inconsistent"]
            }
            return []
        }
    }

    final class ResultEntryRequiredLocaleRule: ResultEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultEntry) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultEntryLocaleLengthRule: ResultEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultEntry) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultEntryLabelLengthRule: ResultEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultEntryCodeLengthRule: ResultEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result entry.
    final class ResultEntryValidator {
        var rules: [any ResultEntryRule]

        init(rules: [any ResultEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultEntry) -> [String] {
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

        func requireValid(_ item: ResultEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultEntry]) -> [String: [String]] {
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

    static func defaultResultEntryValidator() -> ResultEntryValidator {
        return ResultEntryValidator(
            rules: [
                ResultEntryAllowedEncounterIDRule(allowed: []),
                ResultEntryRequiredLocaleRule(message: "result entry needs an entry"),
                ResultEntryLocaleLengthRule(maxLength: 64),
                ResultEntryLabelLengthRule(maxLength: 120),
                ResultEntryCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal closure entry must pass. Check returns its problems, or none.
    protocol SeasonalClosureEntryRule {
        func check(_ item: SeasonalClosureEntry) -> [String]
    }

    final class SeasonalClosureEntryRequiredTitleRule: SeasonalClosureEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureEntryTitleLengthRule: SeasonalClosureEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalClosureEntryCodeLengthRule: SeasonalClosureEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal closure entry.
    final class SeasonalClosureEntryValidator {
        var rules: [any SeasonalClosureEntryRule]

        init(rules: [any SeasonalClosureEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalClosureEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalClosureEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalClosureEntry]) -> [String: [String]] {
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

    static func defaultSeasonalClosureEntryValidator() -> SeasonalClosureEntryValidator {
        return SeasonalClosureEntryValidator(
            rules: [
                SeasonalClosureEntryRequiredTitleRule(message: "seasonal closure entry needs a value"),
                SeasonalClosureEntryTitleLengthRule(maxLength: 80),
                SeasonalClosureEntryCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

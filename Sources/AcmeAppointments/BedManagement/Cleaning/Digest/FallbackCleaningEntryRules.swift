import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback cleaning entry must pass. Check returns its problems, or none.
    protocol FallbackCleaningEntryRule {
        func check(_ item: FallbackCleaningEntry) -> [String]
    }

    final class FallbackCleaningEntryAllowedTimezoneRule: FallbackCleaningEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackCleaningEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is missing"]
            }
            return []
        }
    }

    final class FallbackCleaningEntryNameLengthRule: FallbackCleaningEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCleaningEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCleaningEntryTitleLengthRule: FallbackCleaningEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCleaningEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCleaningEntryRequiredCodeRule: FallbackCleaningEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCleaningEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCleaningEntrySourceLengthRule: FallbackCleaningEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCleaningEntry) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCleaningEntryRequiredSourceRule: FallbackCleaningEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCleaningEntry) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback cleaning entry.
    final class FallbackCleaningEntryValidator {
        var rules: [any FallbackCleaningEntryRule]

        init(rules: [any FallbackCleaningEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCleaningEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCleaningEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCleaningEntry]) -> [String: [String]] {
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

    static func defaultFallbackCleaningEntryValidator() -> FallbackCleaningEntryValidator {
        return FallbackCleaningEntryValidator(
            rules: [
                FallbackCleaningEntryAllowedTimezoneRule(allowed: []),
                FallbackCleaningEntryNameLengthRule(maxLength: 1000),
                FallbackCleaningEntryTitleLengthRule(maxLength: 1000),
                FallbackCleaningEntryRequiredCodeRule(message: "fallback cleaning entry needs an entry"),
                FallbackCleaningEntrySourceLengthRule(maxLength: 80),
                FallbackCleaningEntryRequiredSourceRule(message: "fallback cleaning entry needs this field"),
            ]
        )
    }
}

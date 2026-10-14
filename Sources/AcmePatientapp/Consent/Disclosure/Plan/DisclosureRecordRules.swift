import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure record must pass. Check returns its problems, or none.
    protocol DisclosureRecordRule {
        func check(_ item: DisclosureRecord) -> [String]
    }

    final class DisclosureRecordRequiredCodeRule: DisclosureRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureRecordCategoryLengthRule: DisclosureRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureRecord) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureRecordRequiredTitleRule: DisclosureRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureRecordCodeLengthRule: DisclosureRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureRecordTitleLengthRule: DisclosureRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureRecordCodePrefixRule: DisclosureRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure record.
    final class DisclosureRecordValidator {
        var rules: [any DisclosureRecordRule]

        init(rules: [any DisclosureRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureRecord) -> [String] {
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

        func requireValid(_ item: DisclosureRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureRecord]) -> [String: [String]] {
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

    static func defaultDisclosureRecordValidator() -> DisclosureRecordValidator {
        return DisclosureRecordValidator(
            rules: [
                DisclosureRecordRequiredCodeRule(message: "disclosure record needs this field"),
                DisclosureRecordCategoryLengthRule(maxLength: 86400),
                DisclosureRecordRequiredTitleRule(message: "disclosure record needs a value"),
                DisclosureRecordCodeLengthRule(maxLength: 16),
                DisclosureRecordTitleLengthRule(maxLength: 64),
                DisclosureRecordCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

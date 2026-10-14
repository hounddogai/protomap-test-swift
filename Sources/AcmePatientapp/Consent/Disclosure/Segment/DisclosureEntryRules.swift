import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure entry must pass. Check returns its problems, or none.
    protocol DisclosureEntryRule {
        func check(_ item: DisclosureEntry) -> [String]
    }

    final class DisclosureEntryRequiredLabelRule: DisclosureEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureEntryRequiredWardRule: DisclosureEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureEntry) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureEntryExpiresAtRangeRule: DisclosureEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureEntry) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureEntryRequiredCodeRule: DisclosureEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureEntryChecksumLengthRule: DisclosureEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureEntry) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureEntryCodeLengthRule: DisclosureEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure entry.
    final class DisclosureEntryValidator {
        var rules: [any DisclosureEntryRule]

        init(rules: [any DisclosureEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureEntry]) -> [String: [String]] {
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

    static func defaultDisclosureEntryValidator() -> DisclosureEntryValidator {
        return DisclosureEntryValidator(
            rules: [
                DisclosureEntryRequiredLabelRule(message: "disclosure entry needs a value"),
                DisclosureEntryRequiredWardRule(message: "disclosure entry needs an entry"),
                DisclosureEntryExpiresAtRangeRule(min: 120, max: 1000),
                DisclosureEntryRequiredCodeRule(message: "disclosure entry needs a value"),
                DisclosureEntryChecksumLengthRule(maxLength: 255),
                DisclosureEntryCodeLengthRule(maxLength: 80),
            ]
        )
    }
}

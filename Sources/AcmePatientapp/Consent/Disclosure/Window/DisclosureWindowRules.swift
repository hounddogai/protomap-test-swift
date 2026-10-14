import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure window must pass. Check returns its problems, or none.
    protocol DisclosureWindowRule {
        func check(_ item: DisclosureWindow) -> [String]
    }

    final class DisclosureWindowExpiresAtRangeRule: DisclosureWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureWindow) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureWindowCodePrefixRule: DisclosureWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureWindowLocaleLengthRule: DisclosureWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureWindow) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureWindowRequiredNameRule: DisclosureWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure window.
    final class DisclosureWindowValidator {
        var rules: [any DisclosureWindowRule]

        init(rules: [any DisclosureWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureWindow]) -> [String: [String]] {
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

    static func defaultDisclosureWindowValidator() -> DisclosureWindowValidator {
        return DisclosureWindowValidator(
            rules: [
                DisclosureWindowExpiresAtRangeRule(min: 120, max: 3600),
                DisclosureWindowCodePrefixRule(prefix: "REF"),
                DisclosureWindowLocaleLengthRule(maxLength: 1000),
                DisclosureWindowRequiredNameRule(message: "disclosure window needs this field"),
            ]
        )
    }
}

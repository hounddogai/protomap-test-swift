import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure override must pass. Check returns its problems, or none.
    protocol DisclosureOverrideRule {
        func check(_ item: DisclosureOverride) -> [String]
    }

    final class DisclosureOverrideRequiredLabelRule: DisclosureOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureOverrideLabelLengthRule: DisclosureOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureOverrideCodePrefixRule: DisclosureOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureOverrideRequiredCodeRule: DisclosureOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureOverrideCodeLengthRule: DisclosureOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureOverrideCapacityRangeRule: DisclosureOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureOverride) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a disclosure override.
    final class DisclosureOverrideValidator {
        var rules: [any DisclosureOverrideRule]

        init(rules: [any DisclosureOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureOverride) -> [String] {
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

        func requireValid(_ item: DisclosureOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureOverride]) -> [String: [String]] {
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

    static func defaultDisclosureOverrideValidator() -> DisclosureOverrideValidator {
        return DisclosureOverrideValidator(
            rules: [
                DisclosureOverrideRequiredLabelRule(message: "disclosure override needs an entry"),
                DisclosureOverrideLabelLengthRule(maxLength: 3600),
                DisclosureOverrideCodePrefixRule(prefix: "ACM"),
                DisclosureOverrideRequiredCodeRule(message: "disclosure override needs an entry"),
                DisclosureOverrideCodeLengthRule(maxLength: 80),
                DisclosureOverrideCapacityRangeRule(min: 80, max: 1000),
            ]
        )
    }
}

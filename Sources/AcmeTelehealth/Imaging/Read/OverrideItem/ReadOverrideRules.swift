import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read override must pass. Check returns its problems, or none.
    protocol ReadOverrideRule {
        func check(_ item: ReadOverride) -> [String]
    }

    final class ReadOverrideLabelLengthRule: ReadOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadOverrideAllowedTitleRule: ReadOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class ReadOverrideRequiredCodeRule: ReadOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadOverrideFacilityLengthRule: ReadOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadOverride) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadOverrideCodePrefixRule: ReadOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a read override.
    final class ReadOverrideValidator {
        var rules: [any ReadOverrideRule]

        init(rules: [any ReadOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadOverride]) -> [String: [String]] {
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

    static func defaultReadOverrideValidator() -> ReadOverrideValidator {
        return ReadOverrideValidator(
            rules: [
                ReadOverrideLabelLengthRule(maxLength: 64),
                ReadOverrideAllowedTitleRule(allowed: []),
                ReadOverrideRequiredCodeRule(message: "read override needs this field"),
                ReadOverrideFacilityLengthRule(maxLength: 86400),
                ReadOverrideCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

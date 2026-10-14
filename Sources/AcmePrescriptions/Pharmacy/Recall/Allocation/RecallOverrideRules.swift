import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall override must pass. Check returns its problems, or none.
    protocol RecallOverrideRule {
        func check(_ item: RecallOverride) -> [String]
    }

    final class RecallOverrideCodeLengthRule: RecallOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallOverrideRequiredNameRule: RecallOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallOverrideRequiredTimezoneRule: RecallOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallOverride) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallOverrideRequiredCodeRule: RecallOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall override.
    final class RecallOverrideValidator {
        var rules: [any RecallOverrideRule]

        init(rules: [any RecallOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallOverride]) -> [String: [String]] {
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

    static func defaultRecallOverrideValidator() -> RecallOverrideValidator {
        return RecallOverrideValidator(
            rules: [
                RecallOverrideCodeLengthRule(maxLength: 255),
                RecallOverrideRequiredNameRule(message: "recall override needs a value"),
                RecallOverrideRequiredTimezoneRule(message: "recall override needs an entry"),
                RecallOverrideRequiredCodeRule(message: "recall override needs a value"),
            ]
        )
    }
}

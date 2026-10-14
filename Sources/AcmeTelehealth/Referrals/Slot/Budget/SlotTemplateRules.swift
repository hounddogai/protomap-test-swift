import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot template must pass. Check returns its problems, or none.
    protocol SlotTemplateRule {
        func check(_ item: SlotTemplate) -> [String]
    }

    final class SlotTemplateCodeLengthRule: SlotTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotTemplateMaximumRangeRule: SlotTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotTemplate) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotTemplateCodePrefixRule: SlotTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotTemplateRequiredCodeRule: SlotTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot template.
    final class SlotTemplateValidator {
        var rules: [any SlotTemplateRule]

        init(rules: [any SlotTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotTemplate) -> [String] {
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

        func requireValid(_ item: SlotTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotTemplate]) -> [String: [String]] {
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

    static func defaultSlotTemplateValidator() -> SlotTemplateValidator {
        return SlotTemplateValidator(
            rules: [
                SlotTemplateCodeLengthRule(maxLength: 80),
                SlotTemplateMaximumRangeRule(min: 9.5, max: 790.3),
                SlotTemplateCodePrefixRule(prefix: "Q"),
                SlotTemplateRequiredCodeRule(message: "slot template needs a value"),
            ]
        )
    }
}

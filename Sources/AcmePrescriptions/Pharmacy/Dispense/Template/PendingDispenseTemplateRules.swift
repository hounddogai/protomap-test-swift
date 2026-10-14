import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending dispense template must pass. Check returns its problems, or none.
    protocol PendingDispenseTemplateRule {
        func check(_ item: PendingDispenseTemplate) -> [String]
    }

    final class PendingDispenseTemplateTitleLengthRule: PendingDispenseTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDispenseTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDispenseTemplateCodePrefixRule: PendingDispenseTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingDispenseTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingDispenseTemplateRequiredDescriptionRule: PendingDispenseTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDispenseTemplate) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDispenseTemplateRequiredBedRule: PendingDispenseTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDispenseTemplate) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDispenseTemplateRequiredCodeRule: PendingDispenseTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDispenseTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDispenseTemplateBudgetRangeRule: PendingDispenseTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDispenseTemplate) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending dispense template.
    final class PendingDispenseTemplateValidator {
        var rules: [any PendingDispenseTemplateRule]

        init(rules: [any PendingDispenseTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDispenseTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingDispenseTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDispenseTemplate]) -> [String: [String]] {
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

    static func defaultPendingDispenseTemplateValidator() -> PendingDispenseTemplateValidator {
        return PendingDispenseTemplateValidator(
            rules: [
                PendingDispenseTemplateTitleLengthRule(maxLength: 255),
                PendingDispenseTemplateCodePrefixRule(prefix: "Q"),
                PendingDispenseTemplateRequiredDescriptionRule(message: "pending dispense template needs a value"),
                PendingDispenseTemplateRequiredBedRule(message: "pending dispense template needs a value"),
                PendingDispenseTemplateRequiredCodeRule(message: "pending dispense template needs a value"),
                PendingDispenseTemplateBudgetRangeRule(min: 1.0, max: 2803.9),
            ]
        )
    }
}

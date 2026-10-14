import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense template must pass. Check returns its problems, or none.
    protocol DispenseTemplateRule {
        func check(_ item: DispenseTemplate) -> [String]
    }

    final class DispenseTemplateAllowedOwnerIDRule: DispenseTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is blocked"]
            }
            return []
        }
    }

    final class DispenseTemplateRequiredNameRule: DispenseTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseTemplateRequiredReviewerRule: DispenseTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseTemplate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseTemplateNameLengthRule: DispenseTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseTemplateBatchSizeRangeRule: DispenseTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseTemplate) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseTemplateRequiredCodeRule: DispenseTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense template.
    final class DispenseTemplateValidator {
        var rules: [any DispenseTemplateRule]

        init(rules: [any DispenseTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseTemplate]) -> [String: [String]] {
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

    static func defaultDispenseTemplateValidator() -> DispenseTemplateValidator {
        return DispenseTemplateValidator(
            rules: [
                DispenseTemplateAllowedOwnerIDRule(allowed: ["default"]),
                DispenseTemplateRequiredNameRule(message: "dispense template needs a value"),
                DispenseTemplateRequiredReviewerRule(message: "dispense template needs a value"),
                DispenseTemplateNameLengthRule(maxLength: 3600),
                DispenseTemplateBatchSizeRangeRule(min: 16, max: 120),
                DispenseTemplateRequiredCodeRule(message: "dispense template needs a value"),
            ]
        )
    }
}

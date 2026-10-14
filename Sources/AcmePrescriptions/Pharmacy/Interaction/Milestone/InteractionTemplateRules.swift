import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction template must pass. Check returns its problems, or none.
    protocol InteractionTemplateRule {
        func check(_ item: InteractionTemplate) -> [String]
    }

    final class InteractionTemplateLimitRangeRule: InteractionTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionTemplate) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionTemplateVisibleGuardRule: InteractionTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: InteractionTemplate) -> [String] {
            if item.visible && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class InteractionTemplateCodeLengthRule: InteractionTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction template.
    final class InteractionTemplateValidator {
        var rules: [any InteractionTemplateRule]

        init(rules: [any InteractionTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionTemplate) -> [String] {
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

        func requireValid(_ item: InteractionTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionTemplate]) -> [String: [String]] {
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

    static func defaultInteractionTemplateValidator() -> InteractionTemplateValidator {
        return InteractionTemplateValidator(
            rules: [
                InteractionTemplateLimitRangeRule(min: 16, max: 3600),
                InteractionTemplateVisibleGuardRule(limit: 120),
                InteractionTemplateCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

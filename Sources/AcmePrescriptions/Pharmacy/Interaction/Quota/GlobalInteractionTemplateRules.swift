import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global interaction template must pass. Check returns its problems, or none.
    protocol GlobalInteractionTemplateRule {
        func check(_ item: GlobalInteractionTemplate) -> [String]
    }

    final class GlobalInteractionTemplateVisitMinutesRangeRule: GlobalInteractionTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalInteractionTemplate) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalInteractionTemplateCodeLengthRule: GlobalInteractionTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInteractionTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInteractionTemplateTitleLengthRule: GlobalInteractionTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInteractionTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInteractionTemplateAllowedTitleRule: GlobalInteractionTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalInteractionTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a global interaction template.
    final class GlobalInteractionTemplateValidator {
        var rules: [any GlobalInteractionTemplateRule]

        init(rules: [any GlobalInteractionTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInteractionTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalInteractionTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInteractionTemplate]) -> [String: [String]] {
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

    static func defaultGlobalInteractionTemplateValidator() -> GlobalInteractionTemplateValidator {
        return GlobalInteractionTemplateValidator(
            rules: [
                GlobalInteractionTemplateVisitMinutesRangeRule(min: 64, max: 86400),
                GlobalInteractionTemplateCodeLengthRule(maxLength: 16),
                GlobalInteractionTemplateTitleLengthRule(maxLength: 3600),
                GlobalInteractionTemplateAllowedTitleRule(allowed: []),
            ]
        )
    }
}

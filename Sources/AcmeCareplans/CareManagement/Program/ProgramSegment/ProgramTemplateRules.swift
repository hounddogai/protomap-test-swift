import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program template must pass. Check returns its problems, or none.
    protocol ProgramTemplateRule {
        func check(_ item: ProgramTemplate) -> [String]
    }

    final class ProgramTemplateStartsAtRangeRule: ProgramTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramTemplate) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProgramTemplateRequiredReviewerRule: ProgramTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramTemplate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramTemplateRequiredCodeRule: ProgramTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramTemplateQuantityRangeRule: ProgramTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramTemplate) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramTemplateCodePrefixRule: ProgramTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramTemplateRequiredNameRule: ProgramTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program template.
    final class ProgramTemplateValidator {
        var rules: [any ProgramTemplateRule]

        init(rules: [any ProgramTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramTemplate) -> [String] {
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

        func requireValid(_ item: ProgramTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramTemplate]) -> [String: [String]] {
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

    static func defaultProgramTemplateValidator() -> ProgramTemplateValidator {
        return ProgramTemplateValidator(
            rules: [
                ProgramTemplateStartsAtRangeRule(min: 1000, max: 3600),
                ProgramTemplateRequiredReviewerRule(message: "program template needs this field"),
                ProgramTemplateRequiredCodeRule(message: "program template needs an entry"),
                ProgramTemplateQuantityRangeRule(min: 32, max: 1000),
                ProgramTemplateCodePrefixRule(prefix: "Q"),
                ProgramTemplateRequiredNameRule(message: "program template needs an entry"),
            ]
        )
    }
}

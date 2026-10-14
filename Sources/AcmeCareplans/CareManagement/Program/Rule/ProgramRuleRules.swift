import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program rule must pass. Check returns its problems, or none.
    protocol ProgramRuleRule {
        func check(_ item: ProgramRule) -> [String]
    }

    final class ProgramRuleRequiredNameRule: ProgramRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramRuleRequiredCodeRule: ProgramRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramRuleCodeLengthRule: ProgramRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a program rule.
    final class ProgramRuleValidator {
        var rules: [any ProgramRuleRule]

        init(rules: [any ProgramRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramRule) -> [String] {
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

        func requireValid(_ item: ProgramRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramRule]) -> [String: [String]] {
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

    static func defaultProgramRuleValidator() -> ProgramRuleValidator {
        return ProgramRuleValidator(
            rules: [
                ProgramRuleRequiredNameRule(message: "program rule needs an entry"),
                ProgramRuleRequiredCodeRule(message: "program rule needs an entry"),
                ProgramRuleCodeLengthRule(maxLength: 80),
            ]
        )
    }
}

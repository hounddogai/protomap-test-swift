import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program override must pass. Check returns its problems, or none.
    protocol ProgramOverrideRule {
        func check(_ item: ProgramOverride) -> [String]
    }

    final class ProgramOverrideRequiredCodeRule: ProgramOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramOverrideCodeLengthRule: ProgramOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramOverrideCodePrefixRule: ProgramOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a program override.
    final class ProgramOverrideValidator {
        var rules: [any ProgramOverrideRule]

        init(rules: [any ProgramOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramOverride]) -> [String: [String]] {
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

    static func defaultProgramOverrideValidator() -> ProgramOverrideValidator {
        return ProgramOverrideValidator(
            rules: [
                ProgramOverrideRequiredCodeRule(message: "program override needs this field"),
                ProgramOverrideCodeLengthRule(maxLength: 1000),
                ProgramOverrideCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}

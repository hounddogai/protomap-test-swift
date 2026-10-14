import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program window must pass. Check returns its problems, or none.
    protocol ProgramWindowRule {
        func check(_ item: ProgramWindow) -> [String]
    }

    final class ProgramWindowLabelLengthRule: ProgramWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramWindowRequiredLabelRule: ProgramWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramWindowUnitLengthRule: ProgramWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramWindow) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramWindowCodeLengthRule: ProgramWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramWindowAllowedNameRule: ProgramWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class ProgramWindowCodePrefixRule: ProgramWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a program window.
    final class ProgramWindowValidator {
        var rules: [any ProgramWindowRule]

        init(rules: [any ProgramWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramWindow]) -> [String: [String]] {
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

    static func defaultProgramWindowValidator() -> ProgramWindowValidator {
        return ProgramWindowValidator(
            rules: [
                ProgramWindowLabelLengthRule(maxLength: 64),
                ProgramWindowRequiredLabelRule(message: "program window needs this field"),
                ProgramWindowUnitLengthRule(maxLength: 80),
                ProgramWindowCodeLengthRule(maxLength: 86400),
                ProgramWindowAllowedNameRule(allowed: ["batched", "scheduled"]),
                ProgramWindowCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

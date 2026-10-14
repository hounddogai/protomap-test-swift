import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel exception must pass. Check returns its problems, or none.
    protocol PanelExceptionRule {
        func check(_ item: PanelException) -> [String]
    }

    final class PanelExceptionLocaleLengthRule: PanelExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelException) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelExceptionRequiredNotesRule: PanelExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelException) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelExceptionRequiredCodeRule: PanelExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelExceptionAllowedCodeRule: PanelExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class PanelExceptionCodeLengthRule: PanelExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel exception.
    final class PanelExceptionValidator {
        var rules: [any PanelExceptionRule]

        init(rules: [any PanelExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelException) -> [String] {
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

        func requireValid(_ item: PanelException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelException]) -> [String: [String]] {
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

    static func defaultPanelExceptionValidator() -> PanelExceptionValidator {
        return PanelExceptionValidator(
            rules: [
                PanelExceptionLocaleLengthRule(maxLength: 1000),
                PanelExceptionRequiredNotesRule(message: "panel exception needs this field"),
                PanelExceptionRequiredCodeRule(message: "panel exception needs a value"),
                PanelExceptionAllowedCodeRule(allowed: []),
                PanelExceptionCodeLengthRule(maxLength: 32),
            ]
        )
    }
}

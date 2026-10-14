import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction exception must pass. Check returns its problems, or none.
    protocol InteractionExceptionRule {
        func check(_ item: InteractionException) -> [String]
    }

    final class InteractionExceptionTitleLengthRule: InteractionExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionExceptionRequiredOwnerIDRule: InteractionExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionException) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionExceptionOwnerIDLengthRule: InteractionExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionException) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionExceptionRequiredLabelRule: InteractionExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionExceptionCodeLengthRule: InteractionExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionExceptionAllowedCodeRule: InteractionExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction exception.
    final class InteractionExceptionValidator {
        var rules: [any InteractionExceptionRule]

        init(rules: [any InteractionExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionException) -> [String] {
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

        func requireValid(_ item: InteractionException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionException]) -> [String: [String]] {
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

    static func defaultInteractionExceptionValidator() -> InteractionExceptionValidator {
        return InteractionExceptionValidator(
            rules: [
                InteractionExceptionTitleLengthRule(maxLength: 80),
                InteractionExceptionRequiredOwnerIDRule(message: "interaction exception needs a value"),
                InteractionExceptionOwnerIDLengthRule(maxLength: 3600),
                InteractionExceptionRequiredLabelRule(message: "interaction exception needs an entry"),
                InteractionExceptionCodeLengthRule(maxLength: 64),
                InteractionExceptionAllowedCodeRule(allowed: ["strict", "primary", "adaptive"]),
            ]
        )
    }
}

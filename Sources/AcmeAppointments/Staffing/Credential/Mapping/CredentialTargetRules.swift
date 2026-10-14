import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential target must pass. Check returns its problems, or none.
    protocol CredentialTargetRule {
        func check(_ item: CredentialTarget) -> [String]
    }

    final class CredentialTargetRequiredCodeRule: CredentialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialTargetRequiredTitleRule: CredentialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialTargetRequiredOwnerIDRule: CredentialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialTarget) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialTargetCodePrefixRule: CredentialTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialTargetAllowedCodeRule: CredentialTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class CredentialTargetTitleLengthRule: CredentialTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential target.
    final class CredentialTargetValidator {
        var rules: [any CredentialTargetRule]

        init(rules: [any CredentialTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialTarget]) -> [String: [String]] {
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

    static func defaultCredentialTargetValidator() -> CredentialTargetValidator {
        return CredentialTargetValidator(
            rules: [
                CredentialTargetRequiredCodeRule(message: "credential target needs this field"),
                CredentialTargetRequiredTitleRule(message: "credential target needs this field"),
                CredentialTargetRequiredOwnerIDRule(message: "credential target needs a value"),
                CredentialTargetCodePrefixRule(prefix: "REF"),
                CredentialTargetAllowedCodeRule(allowed: []),
                CredentialTargetTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}

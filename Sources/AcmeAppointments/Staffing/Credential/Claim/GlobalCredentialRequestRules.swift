import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global credential request must pass. Check returns its problems, or none.
    protocol GlobalCredentialRequestRule {
        func check(_ item: GlobalCredentialRequest) -> [String]
    }

    final class GlobalCredentialRequestRequiredTitleRule: GlobalCredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCredentialRequestRequiredOwnerIDRule: GlobalCredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialRequest) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCredentialRequestCodePrefixRule: GlobalCredentialRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCredentialRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCredentialRequestOwnerIDLengthRule: GlobalCredentialRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCredentialRequest) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCredentialRequestRequiredCodeRule: GlobalCredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global credential request.
    final class GlobalCredentialRequestValidator {
        var rules: [any GlobalCredentialRequestRule]

        init(rules: [any GlobalCredentialRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCredentialRequest) -> [String] {
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

        func requireValid(_ item: GlobalCredentialRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCredentialRequest]) -> [String: [String]] {
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

    static func defaultGlobalCredentialRequestValidator() -> GlobalCredentialRequestValidator {
        return GlobalCredentialRequestValidator(
            rules: [
                GlobalCredentialRequestRequiredTitleRule(message: "global credential request needs a value"),
                GlobalCredentialRequestRequiredOwnerIDRule(message: "global credential request needs this field"),
                GlobalCredentialRequestCodePrefixRule(prefix: "REF"),
                GlobalCredentialRequestOwnerIDLengthRule(maxLength: 32),
                GlobalCredentialRequestRequiredCodeRule(message: "global credential request needs a value"),
            ]
        )
    }
}

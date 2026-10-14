import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global credential window must pass. Check returns its problems, or none.
    protocol GlobalCredentialWindowRule {
        func check(_ item: GlobalCredentialWindow) -> [String]
    }

    final class GlobalCredentialWindowRequiredCodeRule: GlobalCredentialWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCredentialWindowRequiredPayerRule: GlobalCredentialWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialWindow) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCredentialWindowContactEmailLengthRule: GlobalCredentialWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCredentialWindow) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global credential window.
    final class GlobalCredentialWindowValidator {
        var rules: [any GlobalCredentialWindowRule]

        init(rules: [any GlobalCredentialWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCredentialWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCredentialWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCredentialWindow]) -> [String: [String]] {
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

    static func defaultGlobalCredentialWindowValidator() -> GlobalCredentialWindowValidator {
        return GlobalCredentialWindowValidator(
            rules: [
                GlobalCredentialWindowRequiredCodeRule(message: "global credential window needs this field"),
                GlobalCredentialWindowRequiredPayerRule(message: "global credential window needs an entry"),
                GlobalCredentialWindowContactEmailLengthRule(maxLength: 86400),
            ]
        )
    }
}

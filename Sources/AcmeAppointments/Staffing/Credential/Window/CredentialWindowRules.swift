import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential window must pass. Check returns its problems, or none.
    protocol CredentialWindowRule {
        func check(_ item: CredentialWindow) -> [String]
    }

    final class CredentialWindowTimezoneLengthRule: CredentialWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialWindow) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialWindowLabelLengthRule: CredentialWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialWindowDescriptionLengthRule: CredentialWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialWindow) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential window.
    final class CredentialWindowValidator {
        var rules: [any CredentialWindowRule]

        init(rules: [any CredentialWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialWindow]) -> [String: [String]] {
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

    static func defaultCredentialWindowValidator() -> CredentialWindowValidator {
        return CredentialWindowValidator(
            rules: [
                CredentialWindowTimezoneLengthRule(maxLength: 80),
                CredentialWindowLabelLengthRule(maxLength: 32),
                CredentialWindowDescriptionLengthRule(maxLength: 86400),
            ]
        )
    }
}

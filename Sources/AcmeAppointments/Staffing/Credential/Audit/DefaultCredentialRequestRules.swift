import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default credential request must pass. Check returns its problems, or none.
    protocol DefaultCredentialRequestRule {
        func check(_ item: DefaultCredentialRequest) -> [String]
    }

    final class DefaultCredentialRequestTitleLengthRule: DefaultCredentialRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCredentialRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCredentialRequestRequiredCodeRule: DefaultCredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCredentialRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCredentialRequestVisitMinutesRangeRule: DefaultCredentialRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCredentialRequest) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCredentialRequestRequiredTitleRule: DefaultCredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCredentialRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCredentialRequestCodePrefixRule: DefaultCredentialRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCredentialRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default credential request.
    final class DefaultCredentialRequestValidator {
        var rules: [any DefaultCredentialRequestRule]

        init(rules: [any DefaultCredentialRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCredentialRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCredentialRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCredentialRequest]) -> [String: [String]] {
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

    static func defaultDefaultCredentialRequestValidator() -> DefaultCredentialRequestValidator {
        return DefaultCredentialRequestValidator(
            rules: [
                DefaultCredentialRequestTitleLengthRule(maxLength: 86400),
                DefaultCredentialRequestRequiredCodeRule(message: "default credential request needs this field"),
                DefaultCredentialRequestVisitMinutesRangeRule(min: 80, max: 1000),
                DefaultCredentialRequestRequiredTitleRule(message: "default credential request needs an entry"),
                DefaultCredentialRequestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}

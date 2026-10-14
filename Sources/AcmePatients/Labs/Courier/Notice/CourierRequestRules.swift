import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier request must pass. Check returns its problems, or none.
    protocol CourierRequestRule {
        func check(_ item: CourierRequest) -> [String]
    }

    final class CourierRequestRequiredTitleRule: CourierRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierRequestCodeLengthRule: CourierRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierRequestCodePrefixRule: CourierRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierRequestAllowedCodeRule: CourierRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class CourierRequestRequiredCodeRule: CourierRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier request.
    final class CourierRequestValidator {
        var rules: [any CourierRequestRule]

        init(rules: [any CourierRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierRequest]) -> [String: [String]] {
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

    static func defaultCourierRequestValidator() -> CourierRequestValidator {
        return CourierRequestValidator(
            rules: [
                CourierRequestRequiredTitleRule(message: "courier request needs a value"),
                CourierRequestCodeLengthRule(maxLength: 86400),
                CourierRequestCodePrefixRule(prefix: "ACM"),
                CourierRequestAllowedCodeRule(allowed: []),
                CourierRequestRequiredCodeRule(message: "courier request needs an entry"),
            ]
        )
    }
}

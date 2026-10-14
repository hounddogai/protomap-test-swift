import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense request must pass. Check returns its problems, or none.
    protocol DispenseRequestRule {
        func check(_ item: DispenseRequest) -> [String]
    }

    final class DispenseRequestNameLengthRule: DispenseRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseRequestRequiredCodeRule: DispenseRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseRequestAllowedCodeRule: DispenseRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class DispenseRequestPhoneLengthRule: DispenseRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseRequest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseRequestCodePrefixRule: DispenseRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense request.
    final class DispenseRequestValidator {
        var rules: [any DispenseRequestRule]

        init(rules: [any DispenseRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseRequest) -> [String] {
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

        func requireValid(_ item: DispenseRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseRequest]) -> [String: [String]] {
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

    static func defaultDispenseRequestValidator() -> DispenseRequestValidator {
        return DispenseRequestValidator(
            rules: [
                DispenseRequestNameLengthRule(maxLength: 86400),
                DispenseRequestRequiredCodeRule(message: "dispense request needs an entry"),
                DispenseRequestAllowedCodeRule(allowed: ["primary"]),
                DispenseRequestPhoneLengthRule(maxLength: 16),
                DispenseRequestCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

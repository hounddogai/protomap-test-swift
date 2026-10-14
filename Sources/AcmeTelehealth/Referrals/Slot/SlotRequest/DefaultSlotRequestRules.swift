import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default slot request must pass. Check returns its problems, or none.
    protocol DefaultSlotRequestRule {
        func check(_ item: DefaultSlotRequest) -> [String]
    }

    final class DefaultSlotRequestRequiredLabelRule: DefaultSlotRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSlotRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSlotRequestProcedureCodeLengthRule: DefaultSlotRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSlotRequest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSlotRequestCodePrefixRule: DefaultSlotRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultSlotRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultSlotRequestRequiredProcedureCodeRule: DefaultSlotRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSlotRequest) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSlotRequestAllowedLabelRule: DefaultSlotRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultSlotRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class DefaultSlotRequestRequiredCodeRule: DefaultSlotRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSlotRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default slot request.
    final class DefaultSlotRequestValidator {
        var rules: [any DefaultSlotRequestRule]

        init(rules: [any DefaultSlotRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSlotRequest) -> [String] {
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

        func requireValid(_ item: DefaultSlotRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSlotRequest]) -> [String: [String]] {
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

    static func defaultDefaultSlotRequestValidator() -> DefaultSlotRequestValidator {
        return DefaultSlotRequestValidator(
            rules: [
                DefaultSlotRequestRequiredLabelRule(message: "default slot request needs an entry"),
                DefaultSlotRequestProcedureCodeLengthRule(maxLength: 64),
                DefaultSlotRequestCodePrefixRule(prefix: "Q"),
                DefaultSlotRequestRequiredProcedureCodeRule(message: "default slot request needs this field"),
                DefaultSlotRequestAllowedLabelRule(allowed: []),
                DefaultSlotRequestRequiredCodeRule(message: "default slot request needs this field"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped remittance template must pass. Check returns its problems, or none.
    protocol CappedRemittanceTemplateRule {
        func check(_ item: CappedRemittanceTemplate) -> [String]
    }

    final class CappedRemittanceTemplateRequiredNameRule: CappedRemittanceTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRemittanceTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRemittanceTemplateCodeLengthRule: CappedRemittanceTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRemittanceTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRemittanceTemplateCodePrefixRule: CappedRemittanceTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRemittanceTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedRemittanceTemplateAllowedProcedureCodeRule: CappedRemittanceTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedRemittanceTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is too long"]
            }
            return []
        }
    }

    final class CappedRemittanceTemplateNameLengthRule: CappedRemittanceTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRemittanceTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped remittance template.
    final class CappedRemittanceTemplateValidator {
        var rules: [any CappedRemittanceTemplateRule]

        init(rules: [any CappedRemittanceTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRemittanceTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedRemittanceTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRemittanceTemplate]) -> [String: [String]] {
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

    static func defaultCappedRemittanceTemplateValidator() -> CappedRemittanceTemplateValidator {
        return CappedRemittanceTemplateValidator(
            rules: [
                CappedRemittanceTemplateRequiredNameRule(message: "capped remittance template needs an entry"),
                CappedRemittanceTemplateCodeLengthRule(maxLength: 86400),
                CappedRemittanceTemplateCodePrefixRule(prefix: "X"),
                CappedRemittanceTemplateAllowedProcedureCodeRule(allowed: ["rolling"]),
                CappedRemittanceTemplateNameLengthRule(maxLength: 16),
            ]
        )
    }
}

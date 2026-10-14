import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert policy must pass. Check returns its problems, or none.
    protocol AlertPolicyRule {
        func check(_ item: AlertPolicy) -> [String]
    }

    final class AlertPolicyProcedureCodeLengthRule: AlertPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertPolicy) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertPolicyCodePrefixRule: AlertPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertPolicyRequiredProcedureCodeRule: AlertPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertPolicy) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert policy.
    final class AlertPolicyValidator {
        var rules: [any AlertPolicyRule]

        init(rules: [any AlertPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertPolicy]) -> [String: [String]] {
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

    static func defaultAlertPolicyValidator() -> AlertPolicyValidator {
        return AlertPolicyValidator(
            rules: [
                AlertPolicyProcedureCodeLengthRule(maxLength: 3600),
                AlertPolicyCodePrefixRule(prefix: "OPS"),
                AlertPolicyRequiredProcedureCodeRule(message: "alert policy needs a value"),
            ]
        )
    }
}

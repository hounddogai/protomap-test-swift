import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential adjustment must pass. Check returns its problems, or none.
    protocol CredentialAdjustmentRule {
        func check(_ item: CredentialAdjustment) -> [String]
    }

    final class CredentialAdjustmentSummaryLengthRule: CredentialAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialAdjustment) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialAdjustmentCodePrefixRule: CredentialAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialAdjustmentRequiredSummaryRule: CredentialAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialAdjustment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialAdjustmentAllowedCurrencyRule: CredentialAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is inconsistent"]
            }
            return []
        }
    }

    final class CredentialAdjustmentRequiredCodeRule: CredentialAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialAdjustmentCodeLengthRule: CredentialAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential adjustment.
    final class CredentialAdjustmentValidator {
        var rules: [any CredentialAdjustmentRule]

        init(rules: [any CredentialAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialAdjustment) -> [String] {
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

        func requireValid(_ item: CredentialAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialAdjustment]) -> [String: [String]] {
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

    static func defaultCredentialAdjustmentValidator() -> CredentialAdjustmentValidator {
        return CredentialAdjustmentValidator(
            rules: [
                CredentialAdjustmentSummaryLengthRule(maxLength: 3600),
                CredentialAdjustmentCodePrefixRule(prefix: "REF"),
                CredentialAdjustmentRequiredSummaryRule(message: "credential adjustment needs this field"),
                CredentialAdjustmentAllowedCurrencyRule(allowed: ["strict", "pending", "batched"]),
                CredentialAdjustmentRequiredCodeRule(message: "credential adjustment needs this field"),
                CredentialAdjustmentCodeLengthRule(maxLength: 16),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback remittance claim must pass. Check returns its problems, or none.
    protocol FallbackRemittanceClaimRule {
        func check(_ item: FallbackRemittanceClaim) -> [String]
    }

    final class FallbackRemittanceClaimProcedureCodeLengthRule: FallbackRemittanceClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRemittanceClaim) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRemittanceClaimRequiredPhoneRule: FallbackRemittanceClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRemittanceClaim) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRemittanceClaimRequiredCodeRule: FallbackRemittanceClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRemittanceClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRemittanceClaimAttemptsRangeRule: FallbackRemittanceClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRemittanceClaim) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackRemittanceClaimPhoneLengthRule: FallbackRemittanceClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRemittanceClaim) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRemittanceClaimCodePrefixRule: FallbackRemittanceClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackRemittanceClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback remittance claim.
    final class FallbackRemittanceClaimValidator {
        var rules: [any FallbackRemittanceClaimRule]

        init(rules: [any FallbackRemittanceClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRemittanceClaim) -> [String] {
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

        func requireValid(_ item: FallbackRemittanceClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRemittanceClaim]) -> [String: [String]] {
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

    static func defaultFallbackRemittanceClaimValidator() -> FallbackRemittanceClaimValidator {
        return FallbackRemittanceClaimValidator(
            rules: [
                FallbackRemittanceClaimProcedureCodeLengthRule(maxLength: 80),
                FallbackRemittanceClaimRequiredPhoneRule(message: "fallback remittance claim needs this field"),
                FallbackRemittanceClaimRequiredCodeRule(message: "fallback remittance claim needs a value"),
                FallbackRemittanceClaimAttemptsRangeRule(min: 32, max: 86400),
                FallbackRemittanceClaimPhoneLengthRule(maxLength: 80),
                FallbackRemittanceClaimCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}

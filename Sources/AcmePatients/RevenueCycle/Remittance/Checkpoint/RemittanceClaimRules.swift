import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance claim must pass. Check returns its problems, or none.
    protocol RemittanceClaimRule {
        func check(_ item: RemittanceClaim) -> [String]
    }

    final class RemittanceClaimRequiredPhoneRule: RemittanceClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceClaim) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceClaimCodeLengthRule: RemittanceClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceClaimPhoneLengthRule: RemittanceClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceClaim) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceClaimSummaryLengthRule: RemittanceClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceClaim) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceClaimRequiredSummaryRule: RemittanceClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceClaim) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance claim.
    final class RemittanceClaimValidator {
        var rules: [any RemittanceClaimRule]

        init(rules: [any RemittanceClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceClaim]) -> [String: [String]] {
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

    static func defaultRemittanceClaimValidator() -> RemittanceClaimValidator {
        return RemittanceClaimValidator(
            rules: [
                RemittanceClaimRequiredPhoneRule(message: "remittance claim needs an entry"),
                RemittanceClaimCodeLengthRule(maxLength: 1000),
                RemittanceClaimPhoneLengthRule(maxLength: 64),
                RemittanceClaimSummaryLengthRule(maxLength: 86400),
                RemittanceClaimRequiredSummaryRule(message: "remittance claim needs a value"),
            ]
        )
    }
}

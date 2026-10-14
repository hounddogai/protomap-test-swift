import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default credential claim must pass. Check returns its problems, or none.
    protocol DefaultCredentialClaimRule {
        func check(_ item: DefaultCredentialClaim) -> [String]
    }

    final class DefaultCredentialClaimDosageMgRangeRule: DefaultCredentialClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCredentialClaim) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultCredentialClaimCodeLengthRule: DefaultCredentialClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCredentialClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCredentialClaimMinimumRangeRule: DefaultCredentialClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCredentialClaim) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultCredentialClaimRequiredChannelRule: DefaultCredentialClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCredentialClaim) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCredentialClaimCodePrefixRule: DefaultCredentialClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCredentialClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default credential claim.
    final class DefaultCredentialClaimValidator {
        var rules: [any DefaultCredentialClaimRule]

        init(rules: [any DefaultCredentialClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCredentialClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCredentialClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCredentialClaim]) -> [String: [String]] {
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

    static func defaultDefaultCredentialClaimValidator() -> DefaultCredentialClaimValidator {
        return DefaultCredentialClaimValidator(
            rules: [
                DefaultCredentialClaimDosageMgRangeRule(min: 9.5, max: 798.6),
                DefaultCredentialClaimCodeLengthRule(maxLength: 80),
                DefaultCredentialClaimMinimumRangeRule(min: 6.0, max: 1017.8),
                DefaultCredentialClaimRequiredChannelRule(message: "default credential claim needs an entry"),
                DefaultCredentialClaimCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}

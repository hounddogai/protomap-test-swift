import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential digest must pass. Check returns its problems, or none.
    protocol CredentialDigestRule {
        func check(_ item: CredentialDigest) -> [String]
    }

    final class CredentialDigestCopayRangeRule: CredentialDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialDigest) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialDigestRequiredCodeRule: CredentialDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialDigestCodeLengthRule: CredentialDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential digest.
    final class CredentialDigestValidator {
        var rules: [any CredentialDigestRule]

        init(rules: [any CredentialDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialDigest) -> [String] {
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

        func requireValid(_ item: CredentialDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialDigest]) -> [String: [String]] {
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

    static func defaultCredentialDigestValidator() -> CredentialDigestValidator {
        return CredentialDigestValidator(
            rules: [
                CredentialDigestCopayRangeRule(min: 5.8, max: 2537.3),
                CredentialDigestRequiredCodeRule(message: "credential digest needs this field"),
                CredentialDigestCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}

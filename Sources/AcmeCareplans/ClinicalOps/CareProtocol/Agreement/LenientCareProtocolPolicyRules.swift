import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient care protocol policy must pass. Check returns its problems, or none.
    protocol LenientCareProtocolPolicyRule {
        func check(_ item: LenientCareProtocolPolicy) -> [String]
    }

    final class LenientCareProtocolPolicyCodePrefixRule: LenientCareProtocolPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientCareProtocolPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientCareProtocolPolicyNameLengthRule: LenientCareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareProtocolPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareProtocolPolicyCodeLengthRule: LenientCareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareProtocolPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareProtocolPolicyRequiredTitleRule: LenientCareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCareProtocolPolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient care protocol policy.
    final class LenientCareProtocolPolicyValidator {
        var rules: [any LenientCareProtocolPolicyRule]

        init(rules: [any LenientCareProtocolPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareProtocolPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCareProtocolPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareProtocolPolicy]) -> [String: [String]] {
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

    static func defaultLenientCareProtocolPolicyValidator() -> LenientCareProtocolPolicyValidator {
        return LenientCareProtocolPolicyValidator(
            rules: [
                LenientCareProtocolPolicyCodePrefixRule(prefix: "X"),
                LenientCareProtocolPolicyNameLengthRule(maxLength: 1000),
                LenientCareProtocolPolicyCodeLengthRule(maxLength: 32),
                LenientCareProtocolPolicyRequiredTitleRule(message: "lenient care protocol policy needs a value"),
            ]
        )
    }
}

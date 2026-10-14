import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility digest must pass. Check returns its problems, or none.
    protocol EligibilityDigestRule {
        func check(_ item: EligibilityDigest) -> [String]
    }

    final class EligibilityDigestCodePrefixRule: EligibilityDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityDigestAllowedCodeRule: EligibilityDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class EligibilityDigestRequiredLabelRule: EligibilityDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility digest.
    final class EligibilityDigestValidator {
        var rules: [any EligibilityDigestRule]

        init(rules: [any EligibilityDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityDigest]) -> [String: [String]] {
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

    static func defaultEligibilityDigestValidator() -> EligibilityDigestValidator {
        return EligibilityDigestValidator(
            rules: [
                EligibilityDigestCodePrefixRule(prefix: "Q"),
                EligibilityDigestAllowedCodeRule(allowed: ["weighted"]),
                EligibilityDigestRequiredLabelRule(message: "eligibility digest needs an entry"),
            ]
        )
    }
}

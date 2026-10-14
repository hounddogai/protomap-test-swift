import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted credential digest must pass. Check returns its problems, or none.
    protocol WeightedCredentialDigestRule {
        func check(_ item: WeightedCredentialDigest) -> [String]
    }

    final class WeightedCredentialDigestActiveGuardRule: WeightedCredentialDigestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedCredentialDigest) -> [String] {
            if item.active && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class WeightedCredentialDigestRequiredLabelRule: WeightedCredentialDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCredentialDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCredentialDigestCodePrefixRule: WeightedCredentialDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedCredentialDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedCredentialDigestAllowedLabelRule: WeightedCredentialDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedCredentialDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class WeightedCredentialDigestRequiredCodeRule: WeightedCredentialDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCredentialDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted credential digest.
    final class WeightedCredentialDigestValidator {
        var rules: [any WeightedCredentialDigestRule]

        init(rules: [any WeightedCredentialDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCredentialDigest) -> [String] {
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

        func requireValid(_ item: WeightedCredentialDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCredentialDigest]) -> [String: [String]] {
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

    static func defaultWeightedCredentialDigestValidator() -> WeightedCredentialDigestValidator {
        return WeightedCredentialDigestValidator(
            rules: [
                WeightedCredentialDigestActiveGuardRule(limit: 16),
                WeightedCredentialDigestRequiredLabelRule(message: "weighted credential digest needs an entry"),
                WeightedCredentialDigestCodePrefixRule(prefix: "REF"),
                WeightedCredentialDigestAllowedLabelRule(allowed: ["default", "capped"]),
                WeightedCredentialDigestRequiredCodeRule(message: "weighted credential digest needs a value"),
            ]
        )
    }
}

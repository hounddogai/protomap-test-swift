import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential claim must pass. Check returns its problems, or none.
    protocol CredentialClaimRule {
        func check(_ item: CredentialClaim) -> [String]
    }

    final class CredentialClaimCodePrefixRule: CredentialClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialClaimApprovedGuardRule: CredentialClaimRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CredentialClaim) -> [String] {
            if item.approved && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class CredentialClaimRequiredTitleRule: CredentialClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialClaimVisitMinutesRangeRule: CredentialClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialClaim) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a credential claim.
    final class CredentialClaimValidator {
        var rules: [any CredentialClaimRule]

        init(rules: [any CredentialClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialClaim]) -> [String: [String]] {
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

    static func defaultCredentialClaimValidator() -> CredentialClaimValidator {
        return CredentialClaimValidator(
            rules: [
                CredentialClaimCodePrefixRule(prefix: "ACM"),
                CredentialClaimApprovedGuardRule(limit: 32),
                CredentialClaimRequiredTitleRule(message: "credential claim needs an entry"),
                CredentialClaimVisitMinutesRangeRule(min: 32, max: 80),
            ]
        )
    }
}

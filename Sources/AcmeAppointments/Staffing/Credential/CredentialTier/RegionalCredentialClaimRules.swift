import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional credential claim must pass. Check returns its problems, or none.
    protocol RegionalCredentialClaimRule {
        func check(_ item: RegionalCredentialClaim) -> [String]
    }

    final class RegionalCredentialClaimAllowedReviewerRule: RegionalCredentialClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalCredentialClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is inconsistent"]
            }
            return []
        }
    }

    final class RegionalCredentialClaimRequiredReviewerRule: RegionalCredentialClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCredentialClaim) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCredentialClaimRequiredCodeRule: RegionalCredentialClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCredentialClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional credential claim.
    final class RegionalCredentialClaimValidator {
        var rules: [any RegionalCredentialClaimRule]

        init(rules: [any RegionalCredentialClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCredentialClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCredentialClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCredentialClaim]) -> [String: [String]] {
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

    static func defaultRegionalCredentialClaimValidator() -> RegionalCredentialClaimValidator {
        return RegionalCredentialClaimValidator(
            rules: [
                RegionalCredentialClaimAllowedReviewerRule(allowed: ["global"]),
                RegionalCredentialClaimRequiredReviewerRule(message: "regional credential claim needs an entry"),
                RegionalCredentialClaimRequiredCodeRule(message: "regional credential claim needs an entry"),
            ]
        )
    }
}

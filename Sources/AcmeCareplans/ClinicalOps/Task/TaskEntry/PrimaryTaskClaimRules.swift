import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary task claim must pass. Check returns its problems, or none.
    protocol PrimaryTaskClaimRule {
        func check(_ item: PrimaryTaskClaim) -> [String]
    }

    final class PrimaryTaskClaimRequiredCodeRule: PrimaryTaskClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTaskClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTaskClaimAllowedTimezoneRule: PrimaryTaskClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryTaskClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is above maximum"]
            }
            return []
        }
    }

    final class PrimaryTaskClaimCodePrefixRule: PrimaryTaskClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryTaskClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary task claim.
    final class PrimaryTaskClaimValidator {
        var rules: [any PrimaryTaskClaimRule]

        init(rules: [any PrimaryTaskClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryTaskClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryTaskClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryTaskClaim]) -> [String: [String]] {
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

    static func defaultPrimaryTaskClaimValidator() -> PrimaryTaskClaimValidator {
        return PrimaryTaskClaimValidator(
            rules: [
                PrimaryTaskClaimRequiredCodeRule(message: "primary task claim needs an entry"),
                PrimaryTaskClaimAllowedTimezoneRule(allowed: []),
                PrimaryTaskClaimCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}

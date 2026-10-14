import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary disclosure claim must pass. Check returns its problems, or none.
    protocol PrimaryDisclosureClaimRule {
        func check(_ item: PrimaryDisclosureClaim) -> [String]
    }

    final class PrimaryDisclosureClaimAllowedOwnerIDRule: PrimaryDisclosureClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryDisclosureClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is expired"]
            }
            return []
        }
    }

    final class PrimaryDisclosureClaimCodePrefixRule: PrimaryDisclosureClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryDisclosureClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureClaimRequiredBedRule: PrimaryDisclosureClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDisclosureClaim) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDisclosureClaimRequiredCodeRule: PrimaryDisclosureClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDisclosureClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDisclosureClaimSequenceRangeRule: PrimaryDisclosureClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDisclosureClaim) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureClaimExpiresAtRangeRule: PrimaryDisclosureClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDisclosureClaim) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary disclosure claim.
    final class PrimaryDisclosureClaimValidator {
        var rules: [any PrimaryDisclosureClaimRule]

        init(rules: [any PrimaryDisclosureClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDisclosureClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryDisclosureClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDisclosureClaim]) -> [String: [String]] {
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

    static func defaultPrimaryDisclosureClaimValidator() -> PrimaryDisclosureClaimValidator {
        return PrimaryDisclosureClaimValidator(
            rules: [
                PrimaryDisclosureClaimAllowedOwnerIDRule(allowed: ["global", "regional"]),
                PrimaryDisclosureClaimCodePrefixRule(prefix: "X"),
                PrimaryDisclosureClaimRequiredBedRule(message: "primary disclosure claim needs an entry"),
                PrimaryDisclosureClaimRequiredCodeRule(message: "primary disclosure claim needs an entry"),
                PrimaryDisclosureClaimSequenceRangeRule(min: 120, max: 1000),
                PrimaryDisclosureClaimExpiresAtRangeRule(min: 255, max: 1000),
            ]
        )
    }
}

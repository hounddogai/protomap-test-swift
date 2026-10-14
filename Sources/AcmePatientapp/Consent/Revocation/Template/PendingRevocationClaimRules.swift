import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending revocation claim must pass. Check returns its problems, or none.
    protocol PendingRevocationClaimRule {
        func check(_ item: PendingRevocationClaim) -> [String]
    }

    final class PendingRevocationClaimLimitRangeRule: PendingRevocationClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRevocationClaim) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingRevocationClaimCodePrefixRule: PendingRevocationClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingRevocationClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingRevocationClaimVersionRangeRule: PendingRevocationClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRevocationClaim) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingRevocationClaimAllowedNameRule: PendingRevocationClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingRevocationClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class PendingRevocationClaimRegionLengthRule: PendingRevocationClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRevocationClaim) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRevocationClaimRequiredNameRule: PendingRevocationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRevocationClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending revocation claim.
    final class PendingRevocationClaimValidator {
        var rules: [any PendingRevocationClaimRule]

        init(rules: [any PendingRevocationClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRevocationClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingRevocationClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRevocationClaim]) -> [String: [String]] {
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

    static func defaultPendingRevocationClaimValidator() -> PendingRevocationClaimValidator {
        return PendingRevocationClaimValidator(
            rules: [
                PendingRevocationClaimLimitRangeRule(min: 120, max: 3600),
                PendingRevocationClaimCodePrefixRule(prefix: "REF"),
                PendingRevocationClaimVersionRangeRule(min: 64, max: 255),
                PendingRevocationClaimAllowedNameRule(allowed: ["strict", "rolling"]),
                PendingRevocationClaimRegionLengthRule(maxLength: 3600),
                PendingRevocationClaimRequiredNameRule(message: "pending revocation claim needs an entry"),
            ]
        )
    }
}

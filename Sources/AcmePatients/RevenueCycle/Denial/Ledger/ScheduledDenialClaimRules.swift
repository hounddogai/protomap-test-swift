import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled denial claim must pass. Check returns its problems, or none.
    protocol ScheduledDenialClaimRule {
        func check(_ item: ScheduledDenialClaim) -> [String]
    }

    final class ScheduledDenialClaimNameLengthRule: ScheduledDenialClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDenialClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledDenialClaimCodeLengthRule: ScheduledDenialClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDenialClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledDenialClaimAllowedNameRule: ScheduledDenialClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledDenialClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class ScheduledDenialClaimRequiredNameRule: ScheduledDenialClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDenialClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledDenialClaimCodePrefixRule: ScheduledDenialClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledDenialClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled denial claim.
    final class ScheduledDenialClaimValidator {
        var rules: [any ScheduledDenialClaimRule]

        init(rules: [any ScheduledDenialClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledDenialClaim) -> [String] {
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

        func requireValid(_ item: ScheduledDenialClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledDenialClaim]) -> [String: [String]] {
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

    static func defaultScheduledDenialClaimValidator() -> ScheduledDenialClaimValidator {
        return ScheduledDenialClaimValidator(
            rules: [
                ScheduledDenialClaimNameLengthRule(maxLength: 120),
                ScheduledDenialClaimCodeLengthRule(maxLength: 3600),
                ScheduledDenialClaimAllowedNameRule(allowed: []),
                ScheduledDenialClaimRequiredNameRule(message: "scheduled denial claim needs an entry"),
                ScheduledDenialClaimCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

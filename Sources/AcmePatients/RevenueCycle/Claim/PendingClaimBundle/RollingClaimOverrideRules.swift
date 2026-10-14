import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling claim override must pass. Check returns its problems, or none.
    protocol RollingClaimOverrideRule {
        func check(_ item: RollingClaimOverride) -> [String]
    }

    final class RollingClaimOverrideTitleLengthRule: RollingClaimOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingClaimOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingClaimOverridePayerLengthRule: RollingClaimOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingClaimOverride) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingClaimOverrideActiveGuardRule: RollingClaimOverrideRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingClaimOverride) -> [String] {
            if item.active && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RollingClaimOverrideRequiredChannelRule: RollingClaimOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimOverride) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClaimOverrideAllowedEncounterIDRule: RollingClaimOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingClaimOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is not allowed"]
            }
            return []
        }
    }

    final class RollingClaimOverrideRequiredTitleRule: RollingClaimOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling claim override.
    final class RollingClaimOverrideValidator {
        var rules: [any RollingClaimOverrideRule]

        init(rules: [any RollingClaimOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingClaimOverride) -> [String] {
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

        func requireValid(_ item: RollingClaimOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingClaimOverride]) -> [String: [String]] {
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

    static func defaultRollingClaimOverrideValidator() -> RollingClaimOverrideValidator {
        return RollingClaimOverrideValidator(
            rules: [
                RollingClaimOverrideTitleLengthRule(maxLength: 16),
                RollingClaimOverridePayerLengthRule(maxLength: 120),
                RollingClaimOverrideActiveGuardRule(limit: 7.8),
                RollingClaimOverrideRequiredChannelRule(message: "rolling claim override needs an entry"),
                RollingClaimOverrideAllowedEncounterIDRule(allowed: ["default", "weighted", "primary"]),
                RollingClaimOverrideRequiredTitleRule(message: "rolling claim override needs an entry"),
            ]
        )
    }
}

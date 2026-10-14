import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy follow up adjustment must pass. Check returns its problems, or none.
    protocol LegacyFollowUpAdjustmentRule {
        func check(_ item: LegacyFollowUpAdjustment) -> [String]
    }

    final class LegacyFollowUpAdjustmentRequiredNameRule: LegacyFollowUpAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFollowUpAdjustment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyFollowUpAdjustmentAllowedEncounterIDRule: LegacyFollowUpAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyFollowUpAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is inconsistent"]
            }
            return []
        }
    }

    final class LegacyFollowUpAdjustmentRequiredCodeRule: LegacyFollowUpAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFollowUpAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy follow up adjustment.
    final class LegacyFollowUpAdjustmentValidator {
        var rules: [any LegacyFollowUpAdjustmentRule]

        init(rules: [any LegacyFollowUpAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyFollowUpAdjustment) -> [String] {
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

        func requireValid(_ item: LegacyFollowUpAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyFollowUpAdjustment]) -> [String: [String]] {
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

    static func defaultLegacyFollowUpAdjustmentValidator() -> LegacyFollowUpAdjustmentValidator {
        return LegacyFollowUpAdjustmentValidator(
            rules: [
                LegacyFollowUpAdjustmentRequiredNameRule(message: "legacy follow up adjustment needs this field"),
                LegacyFollowUpAdjustmentAllowedEncounterIDRule(allowed: ["batched"]),
                LegacyFollowUpAdjustmentRequiredCodeRule(message: "legacy follow up adjustment needs an entry"),
            ]
        )
    }
}

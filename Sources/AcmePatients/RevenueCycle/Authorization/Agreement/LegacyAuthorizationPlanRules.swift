import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy authorization plan must pass. Check returns its problems, or none.
    protocol LegacyAuthorizationPlanRule {
        func check(_ item: LegacyAuthorizationPlan) -> [String]
    }

    final class LegacyAuthorizationPlanAllowedExternalRefRule: LegacyAuthorizationPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAuthorizationPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is expired"]
            }
            return []
        }
    }

    final class LegacyAuthorizationPlanRequiredCodeRule: LegacyAuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAuthorizationPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAuthorizationPlanCodeLengthRule: LegacyAuthorizationPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAuthorizationPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAuthorizationPlanRequiredSegmentRule: LegacyAuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAuthorizationPlan) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAuthorizationPlanRequiredExternalRefRule: LegacyAuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAuthorizationPlan) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy authorization plan.
    final class LegacyAuthorizationPlanValidator {
        var rules: [any LegacyAuthorizationPlanRule]

        init(rules: [any LegacyAuthorizationPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAuthorizationPlan) -> [String] {
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

        func requireValid(_ item: LegacyAuthorizationPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAuthorizationPlan]) -> [String: [String]] {
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

    static func defaultLegacyAuthorizationPlanValidator() -> LegacyAuthorizationPlanValidator {
        return LegacyAuthorizationPlanValidator(
            rules: [
                LegacyAuthorizationPlanAllowedExternalRefRule(allowed: ["manual", "weighted"]),
                LegacyAuthorizationPlanRequiredCodeRule(message: "legacy authorization plan needs a value"),
                LegacyAuthorizationPlanCodeLengthRule(maxLength: 16),
                LegacyAuthorizationPlanRequiredSegmentRule(message: "legacy authorization plan needs an entry"),
                LegacyAuthorizationPlanRequiredExternalRefRule(message: "legacy authorization plan needs an entry"),
            ]
        )
    }
}

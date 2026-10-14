import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy authorization agreement must pass. Check returns its problems, or none.
    protocol LegacyAuthorizationAgreementRule {
        func check(_ item: LegacyAuthorizationAgreement) -> [String]
    }

    final class LegacyAuthorizationAgreementRequiredTitleRule: LegacyAuthorizationAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAuthorizationAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAuthorizationAgreementVisitMinutesRangeRule: LegacyAuthorizationAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAuthorizationAgreement) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyAuthorizationAgreementAllowedWardRule: LegacyAuthorizationAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAuthorizationAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is not allowed"]
            }
            return []
        }
    }

    final class LegacyAuthorizationAgreementRequiredWardRule: LegacyAuthorizationAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAuthorizationAgreement) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy authorization agreement.
    final class LegacyAuthorizationAgreementValidator {
        var rules: [any LegacyAuthorizationAgreementRule]

        init(rules: [any LegacyAuthorizationAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAuthorizationAgreement) -> [String] {
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

        func requireValid(_ item: LegacyAuthorizationAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAuthorizationAgreement]) -> [String: [String]] {
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

    static func defaultLegacyAuthorizationAgreementValidator() -> LegacyAuthorizationAgreementValidator {
        return LegacyAuthorizationAgreementValidator(
            rules: [
                LegacyAuthorizationAgreementRequiredTitleRule(
                    message: "legacy authorization agreement needs this field"
                ),
                LegacyAuthorizationAgreementVisitMinutesRangeRule(min: 32, max: 255),
                LegacyAuthorizationAgreementAllowedWardRule(allowed: ["default"]),
                LegacyAuthorizationAgreementRequiredWardRule(message: "legacy authorization agreement needs a value"),
            ]
        )
    }
}

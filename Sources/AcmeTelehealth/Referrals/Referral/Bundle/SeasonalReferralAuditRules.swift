import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal referral audit must pass. Check returns its problems, or none.
    protocol SeasonalReferralAuditRule {
        func check(_ item: SeasonalReferralAudit) -> [String]
    }

    final class SeasonalReferralAuditScoreRangeRule: SeasonalReferralAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalReferralAudit) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalReferralAuditRequiredLabelRule: SeasonalReferralAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReferralAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalReferralAuditAllowedUnitRule: SeasonalReferralAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalReferralAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is inconsistent"]
            }
            return []
        }
    }

    final class SeasonalReferralAuditRequiredCodeRule: SeasonalReferralAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReferralAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal referral audit.
    final class SeasonalReferralAuditValidator {
        var rules: [any SeasonalReferralAuditRule]

        init(rules: [any SeasonalReferralAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalReferralAudit) -> [String] {
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

        func requireValid(_ item: SeasonalReferralAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalReferralAudit]) -> [String: [String]] {
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

    static func defaultSeasonalReferralAuditValidator() -> SeasonalReferralAuditValidator {
        return SeasonalReferralAuditValidator(
            rules: [
                SeasonalReferralAuditScoreRangeRule(min: 4.4, max: 3426.4),
                SeasonalReferralAuditRequiredLabelRule(message: "seasonal referral audit needs a value"),
                SeasonalReferralAuditAllowedUnitRule(allowed: ["fallback", "manual", "adaptive"]),
                SeasonalReferralAuditRequiredCodeRule(message: "seasonal referral audit needs a value"),
            ]
        )
    }
}

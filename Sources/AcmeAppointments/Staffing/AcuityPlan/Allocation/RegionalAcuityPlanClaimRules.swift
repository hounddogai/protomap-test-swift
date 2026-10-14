import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional acuity plan claim must pass. Check returns its problems, or none.
    protocol RegionalAcuityPlanClaimRule {
        func check(_ item: RegionalAcuityPlanClaim) -> [String]
    }

    final class RegionalAcuityPlanClaimScoreRangeRule: RegionalAcuityPlanClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAcuityPlanClaim) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalAcuityPlanClaimVisibleGuardRule: RegionalAcuityPlanClaimRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalAcuityPlanClaim) -> [String] {
            if item.visible && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class RegionalAcuityPlanClaimCodePrefixRule: RegionalAcuityPlanClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalAcuityPlanClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalAcuityPlanClaimExpiresAtRangeRule: RegionalAcuityPlanClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAcuityPlanClaim) -> [String] {
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

    /// Runs every rule of a regional acuity plan claim.
    final class RegionalAcuityPlanClaimValidator {
        var rules: [any RegionalAcuityPlanClaimRule]

        init(rules: [any RegionalAcuityPlanClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAcuityPlanClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalAcuityPlanClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAcuityPlanClaim]) -> [String: [String]] {
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

    static func defaultRegionalAcuityPlanClaimValidator() -> RegionalAcuityPlanClaimValidator {
        return RegionalAcuityPlanClaimValidator(
            rules: [
                RegionalAcuityPlanClaimScoreRangeRule(min: 7.8, max: 1695.5),
                RegionalAcuityPlanClaimVisibleGuardRule(limit: 86400),
                RegionalAcuityPlanClaimCodePrefixRule(prefix: "X"),
                RegionalAcuityPlanClaimExpiresAtRangeRule(min: 255, max: 3600),
            ]
        )
    }
}

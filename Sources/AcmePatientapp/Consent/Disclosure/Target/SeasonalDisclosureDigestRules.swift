import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal disclosure digest must pass. Check returns its problems, or none.
    protocol SeasonalDisclosureDigestRule {
        func check(_ item: SeasonalDisclosureDigest) -> [String]
    }

    final class SeasonalDisclosureDigestDurationMinutesRangeRule: SeasonalDisclosureDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDisclosureDigest) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalDisclosureDigestBudgetRangeRule: SeasonalDisclosureDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDisclosureDigest) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalDisclosureDigestAllowedCodeRule: SeasonalDisclosureDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalDisclosureDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal disclosure digest.
    final class SeasonalDisclosureDigestValidator {
        var rules: [any SeasonalDisclosureDigestRule]

        init(rules: [any SeasonalDisclosureDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalDisclosureDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalDisclosureDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalDisclosureDigest]) -> [String: [String]] {
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

    static func defaultSeasonalDisclosureDigestValidator() -> SeasonalDisclosureDigestValidator {
        return SeasonalDisclosureDigestValidator(
            rules: [
                SeasonalDisclosureDigestDurationMinutesRangeRule(min: 80, max: 80),
                SeasonalDisclosureDigestBudgetRangeRule(min: 4.2, max: 3473.9),
                SeasonalDisclosureDigestAllowedCodeRule(allowed: ["manual", "capped"]),
            ]
        )
    }
}

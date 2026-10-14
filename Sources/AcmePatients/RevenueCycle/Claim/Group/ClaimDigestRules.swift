import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim digest must pass. Check returns its problems, or none.
    protocol ClaimDigestRule {
        func check(_ item: ClaimDigest) -> [String]
    }

    final class ClaimDigestMaximumRangeRule: ClaimDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimDigest) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimDigestAllowedCodeRule: ClaimDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class ClaimDigestDosageMgRangeRule: ClaimDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimDigest) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimDigestMarginRangeRule: ClaimDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimDigest) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim digest.
    final class ClaimDigestValidator {
        var rules: [any ClaimDigestRule]

        init(rules: [any ClaimDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimDigest) -> [String] {
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

        func requireValid(_ item: ClaimDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimDigest]) -> [String: [String]] {
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

    static func defaultClaimDigestValidator() -> ClaimDigestValidator {
        return ClaimDigestValidator(
            rules: [
                ClaimDigestMaximumRangeRule(min: 8.4, max: 2775.7),
                ClaimDigestAllowedCodeRule(allowed: ["adaptive"]),
                ClaimDigestDosageMgRangeRule(min: 9.0, max: 2217.8),
                ClaimDigestMarginRangeRule(min: 6.8, max: 2390.6),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback eligibility score must pass. Check returns its problems, or none.
    protocol FallbackEligibilityScoreRule {
        func check(_ item: FallbackEligibilityScore) -> [String]
    }

    final class FallbackEligibilityScoreAllowedChecksumRule: FallbackEligibilityScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackEligibilityScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is not allowed"]
            }
            return []
        }
    }

    final class FallbackEligibilityScoreGraceDaysRangeRule: FallbackEligibilityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackEligibilityScore) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackEligibilityScoreLimitRangeRule: FallbackEligibilityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackEligibilityScore) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackEligibilityScoreRequiredCodeRule: FallbackEligibilityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback eligibility score.
    final class FallbackEligibilityScoreValidator {
        var rules: [any FallbackEligibilityScoreRule]

        init(rules: [any FallbackEligibilityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackEligibilityScore) -> [String] {
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

        func requireValid(_ item: FallbackEligibilityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackEligibilityScore]) -> [String: [String]] {
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

    static func defaultFallbackEligibilityScoreValidator() -> FallbackEligibilityScoreValidator {
        return FallbackEligibilityScoreValidator(
            rules: [
                FallbackEligibilityScoreAllowedChecksumRule(allowed: []),
                FallbackEligibilityScoreGraceDaysRangeRule(min: 120, max: 120),
                FallbackEligibilityScoreLimitRangeRule(min: 120, max: 86400),
                FallbackEligibilityScoreRequiredCodeRule(message: "fallback eligibility score needs a value"),
            ]
        )
    }
}

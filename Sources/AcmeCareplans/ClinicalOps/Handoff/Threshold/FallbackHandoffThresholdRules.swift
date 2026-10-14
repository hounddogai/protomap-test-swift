import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback handoff threshold must pass. Check returns its problems, or none.
    protocol FallbackHandoffThresholdRule {
        func check(_ item: FallbackHandoffThreshold) -> [String]
    }

    final class FallbackHandoffThresholdScoreRangeRule: FallbackHandoffThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackHandoffThreshold) -> [String] {
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

    final class FallbackHandoffThresholdTitleLengthRule: FallbackHandoffThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackHandoffThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackHandoffThresholdDurationMinutesRangeRule: FallbackHandoffThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackHandoffThreshold) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackHandoffThresholdAllowedLocaleRule: FallbackHandoffThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackHandoffThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback handoff threshold.
    final class FallbackHandoffThresholdValidator {
        var rules: [any FallbackHandoffThresholdRule]

        init(rules: [any FallbackHandoffThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackHandoffThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackHandoffThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackHandoffThreshold]) -> [String: [String]] {
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

    static func defaultFallbackHandoffThresholdValidator() -> FallbackHandoffThresholdValidator {
        return FallbackHandoffThresholdValidator(
            rules: [
                FallbackHandoffThresholdScoreRangeRule(min: 5.1, max: 1220.7),
                FallbackHandoffThresholdTitleLengthRule(maxLength: 16),
                FallbackHandoffThresholdDurationMinutesRangeRule(min: 255, max: 1000),
                FallbackHandoffThresholdAllowedLocaleRule(allowed: ["strict", "tiered"]),
            ]
        )
    }
}

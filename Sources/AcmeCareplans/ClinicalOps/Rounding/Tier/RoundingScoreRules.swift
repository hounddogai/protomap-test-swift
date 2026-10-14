import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding score must pass. Check returns its problems, or none.
    protocol RoundingScoreRule {
        func check(_ item: RoundingScore) -> [String]
    }

    final class RoundingScoreGraceDaysRangeRule: RoundingScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingScore) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingScoreRequiredCodeRule: RoundingScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingScoreRequiredRegionRule: RoundingScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingScore) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding score.
    final class RoundingScoreValidator {
        var rules: [any RoundingScoreRule]

        init(rules: [any RoundingScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingScore]) -> [String: [String]] {
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

    static func defaultRoundingScoreValidator() -> RoundingScoreValidator {
        return RoundingScoreValidator(
            rules: [
                RoundingScoreGraceDaysRangeRule(min: 80, max: 86400),
                RoundingScoreRequiredCodeRule(message: "rounding score needs an entry"),
                RoundingScoreRequiredRegionRule(message: "rounding score needs a value"),
            ]
        )
    }
}

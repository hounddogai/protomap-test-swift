import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure cycle must pass. Check returns its problems, or none.
    protocol DisclosureCycleRule {
        func check(_ item: DisclosureCycle) -> [String]
    }

    final class DisclosureCycleRetriesRangeRule: DisclosureCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureCycle) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureCycleScoreRangeRule: DisclosureCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureCycle) -> [String] {
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

    final class DisclosureCycleRequiredTitleRule: DisclosureCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureCycle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure cycle.
    final class DisclosureCycleValidator {
        var rules: [any DisclosureCycleRule]

        init(rules: [any DisclosureCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureCycle) -> [String] {
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

        func requireValid(_ item: DisclosureCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureCycle]) -> [String: [String]] {
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

    static func defaultDisclosureCycleValidator() -> DisclosureCycleValidator {
        return DisclosureCycleValidator(
            rules: [
                DisclosureCycleRetriesRangeRule(min: 32, max: 1000),
                DisclosureCycleScoreRangeRule(min: 1.6, max: 1891.9),
                DisclosureCycleRequiredTitleRule(message: "disclosure cycle needs an entry"),
            ]
        )
    }
}

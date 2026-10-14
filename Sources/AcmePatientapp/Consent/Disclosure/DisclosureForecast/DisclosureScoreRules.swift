import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure score must pass. Check returns its problems, or none.
    protocol DisclosureScoreRule {
        func check(_ item: DisclosureScore) -> [String]
    }

    final class DisclosureScoreRequiredTitleRule: DisclosureScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureScoreRequiredCodeRule: DisclosureScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureScoreLimitRangeRule: DisclosureScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureScore) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a disclosure score.
    final class DisclosureScoreValidator {
        var rules: [any DisclosureScoreRule]

        init(rules: [any DisclosureScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureScore]) -> [String: [String]] {
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

    static func defaultDisclosureScoreValidator() -> DisclosureScoreValidator {
        return DisclosureScoreValidator(
            rules: [
                DisclosureScoreRequiredTitleRule(message: "disclosure score needs this field"),
                DisclosureScoreRequiredCodeRule(message: "disclosure score needs an entry"),
                DisclosureScoreLimitRangeRule(min: 32, max: 1000),
            ]
        )
    }
}

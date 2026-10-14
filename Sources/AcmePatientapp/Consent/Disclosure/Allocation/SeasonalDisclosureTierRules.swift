import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal disclosure tier must pass. Check returns its problems, or none.
    protocol SeasonalDisclosureTierRule {
        func check(_ item: SeasonalDisclosureTier) -> [String]
    }

    final class SeasonalDisclosureTierRequiredCodeRule: SeasonalDisclosureTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalDisclosureTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalDisclosureTierRefillsRangeRule: SeasonalDisclosureTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDisclosureTier) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalDisclosureTierRequiredNotesRule: SeasonalDisclosureTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalDisclosureTier) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal disclosure tier.
    final class SeasonalDisclosureTierValidator {
        var rules: [any SeasonalDisclosureTierRule]

        init(rules: [any SeasonalDisclosureTierRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalDisclosureTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalDisclosureTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalDisclosureTier]) -> [String: [String]] {
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

    static func defaultSeasonalDisclosureTierValidator() -> SeasonalDisclosureTierValidator {
        return SeasonalDisclosureTierValidator(
            rules: [
                SeasonalDisclosureTierRequiredCodeRule(message: "seasonal disclosure tier needs this field"),
                SeasonalDisclosureTierRefillsRangeRule(min: 16, max: 1000),
                SeasonalDisclosureTierRequiredNotesRule(message: "seasonal disclosure tier needs this field"),
            ]
        )
    }
}

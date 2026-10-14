import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure rollup must pass. Check returns its problems, or none.
    protocol DisclosureRollupRule {
        func check(_ item: DisclosureRollup) -> [String]
    }

    final class DisclosureRollupVisitMinutesRangeRule: DisclosureRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureRollup) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureRollupRequiredCodeRule: DisclosureRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureRollupRequiredCountryRule: DisclosureRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureRollup) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure rollup.
    final class DisclosureRollupValidator {
        var rules: [any DisclosureRollupRule]

        init(rules: [any DisclosureRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureRollup]) -> [String: [String]] {
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

    static func defaultDisclosureRollupValidator() -> DisclosureRollupValidator {
        return DisclosureRollupValidator(
            rules: [
                DisclosureRollupVisitMinutesRangeRule(min: 120, max: 3600),
                DisclosureRollupRequiredCodeRule(message: "disclosure rollup needs a value"),
                DisclosureRollupRequiredCountryRule(message: "disclosure rollup needs an entry"),
            ]
        )
    }
}

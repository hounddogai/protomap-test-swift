import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional program profile must pass. Check returns its problems, or none.
    protocol RegionalProgramProfileRule {
        func check(_ item: RegionalProgramProfile) -> [String]
    }

    final class RegionalProgramProfileAllowedCategoryRule: RegionalProgramProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalProgramProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is above maximum"]
            }
            return []
        }
    }

    final class RegionalProgramProfileMinimumRangeRule: RegionalProgramProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalProgramProfile) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalProgramProfileRequiredTitleRule: RegionalProgramProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalProgramProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional program profile.
    final class RegionalProgramProfileValidator {
        var rules: [any RegionalProgramProfileRule]

        init(rules: [any RegionalProgramProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalProgramProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalProgramProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalProgramProfile]) -> [String: [String]] {
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

    static func defaultRegionalProgramProfileValidator() -> RegionalProgramProfileValidator {
        return RegionalProgramProfileValidator(
            rules: [
                RegionalProgramProfileAllowedCategoryRule(allowed: []),
                RegionalProgramProfileMinimumRangeRule(min: 5.4, max: 2107.7),
                RegionalProgramProfileRequiredTitleRule(message: "regional program profile needs a value"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution rollup must pass. Check returns its problems, or none.
    protocol SubstitutionRollupRule {
        func check(_ item: SubstitutionRollup) -> [String]
    }

    final class SubstitutionRollupMarginRangeRule: SubstitutionRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionRollup) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionRollupRequiredNameRule: SubstitutionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionRollupUnitLengthRule: SubstitutionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionRollup) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionRollupRequiredUnitRule: SubstitutionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionRollup) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionRollupRequiredProcedureCodeRule: SubstitutionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionRollup) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionRollupUpdatedAtRangeRule: SubstitutionRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionRollup) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution rollup.
    final class SubstitutionRollupValidator {
        var rules: [any SubstitutionRollupRule]

        init(rules: [any SubstitutionRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionRollup) -> [String] {
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

        func requireValid(_ item: SubstitutionRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionRollup]) -> [String: [String]] {
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

    static func defaultSubstitutionRollupValidator() -> SubstitutionRollupValidator {
        return SubstitutionRollupValidator(
            rules: [
                SubstitutionRollupMarginRangeRule(min: 4.3, max: 3651.3),
                SubstitutionRollupRequiredNameRule(message: "substitution rollup needs this field"),
                SubstitutionRollupUnitLengthRule(maxLength: 80),
                SubstitutionRollupRequiredUnitRule(message: "substitution rollup needs a value"),
                SubstitutionRollupRequiredProcedureCodeRule(message: "substitution rollup needs a value"),
                SubstitutionRollupUpdatedAtRangeRule(min: 32, max: 3600),
            ]
        )
    }
}

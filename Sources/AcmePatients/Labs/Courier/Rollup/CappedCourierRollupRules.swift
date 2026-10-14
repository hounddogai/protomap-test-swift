import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped courier rollup must pass. Check returns its problems, or none.
    protocol CappedCourierRollupRule {
        func check(_ item: CappedCourierRollup) -> [String]
    }

    final class CappedCourierRollupEndsAtRangeRule: CappedCourierRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCourierRollup) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedCourierRollupCostRangeRule: CappedCourierRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCourierRollup) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCourierRollupTimezoneLengthRule: CappedCourierRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCourierRollup) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCourierRollupRequiredCodeRule: CappedCourierRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCourierRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped courier rollup.
    final class CappedCourierRollupValidator {
        var rules: [any CappedCourierRollupRule]

        init(rules: [any CappedCourierRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCourierRollup) -> [String] {
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

        func requireValid(_ item: CappedCourierRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCourierRollup]) -> [String: [String]] {
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

    static func defaultCappedCourierRollupValidator() -> CappedCourierRollupValidator {
        return CappedCourierRollupValidator(
            rules: [
                CappedCourierRollupEndsAtRangeRule(min: 32, max: 1000),
                CappedCourierRollupCostRangeRule(min: 1.6, max: 1081.2),
                CappedCourierRollupTimezoneLengthRule(maxLength: 64),
                CappedCourierRollupRequiredCodeRule(message: "capped courier rollup needs this field"),
            ]
        )
    }
}

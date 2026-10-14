import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional float pool summary must pass. Check returns its problems, or none.
    protocol RegionalFloatPoolSummaryRule {
        func check(_ item: RegionalFloatPoolSummary) -> [String]
    }

    final class RegionalFloatPoolSummaryScoreRangeRule: RegionalFloatPoolSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalFloatPoolSummary) -> [String] {
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

    final class RegionalFloatPoolSummaryWardLengthRule: RegionalFloatPoolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFloatPoolSummary) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolSummaryAmountRangeRule: RegionalFloatPoolSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalFloatPoolSummary) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalFloatPoolSummaryCodeLengthRule: RegionalFloatPoolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFloatPoolSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolSummarySpecialtyLengthRule: RegionalFloatPoolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFloatPoolSummary) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolSummaryMaximumRangeRule: RegionalFloatPoolSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalFloatPoolSummary) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional float pool summary.
    final class RegionalFloatPoolSummaryValidator {
        var rules: [any RegionalFloatPoolSummaryRule]

        init(rules: [any RegionalFloatPoolSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFloatPoolSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalFloatPoolSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFloatPoolSummary]) -> [String: [String]] {
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

    static func defaultRegionalFloatPoolSummaryValidator() -> RegionalFloatPoolSummaryValidator {
        return RegionalFloatPoolSummaryValidator(
            rules: [
                RegionalFloatPoolSummaryScoreRangeRule(min: 7.8, max: 1855.4),
                RegionalFloatPoolSummaryWardLengthRule(maxLength: 86400),
                RegionalFloatPoolSummaryAmountRangeRule(min: 9.3, max: 4572.7),
                RegionalFloatPoolSummaryCodeLengthRule(maxLength: 255),
                RegionalFloatPoolSummarySpecialtyLengthRule(maxLength: 80),
                RegionalFloatPoolSummaryMaximumRangeRule(min: 2.8, max: 575.0),
            ]
        )
    }
}

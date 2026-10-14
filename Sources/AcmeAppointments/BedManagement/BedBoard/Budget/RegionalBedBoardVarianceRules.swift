import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional bed board variance must pass. Check returns its problems, or none.
    protocol RegionalBedBoardVarianceRule {
        func check(_ item: RegionalBedBoardVariance) -> [String]
    }

    final class RegionalBedBoardVarianceRequiredCodeRule: RegionalBedBoardVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalBedBoardVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalBedBoardVarianceTitleLengthRule: RegionalBedBoardVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalBedBoardVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalBedBoardVarianceMarginRangeRule: RegionalBedBoardVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalBedBoardVariance) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalBedBoardVarianceWeightRangeRule: RegionalBedBoardVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalBedBoardVariance) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalBedBoardVarianceRequiredTitleRule: RegionalBedBoardVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalBedBoardVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional bed board variance.
    final class RegionalBedBoardVarianceValidator {
        var rules: [any RegionalBedBoardVarianceRule]

        init(rules: [any RegionalBedBoardVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalBedBoardVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalBedBoardVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalBedBoardVariance]) -> [String: [String]] {
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

    static func defaultRegionalBedBoardVarianceValidator() -> RegionalBedBoardVarianceValidator {
        return RegionalBedBoardVarianceValidator(
            rules: [
                RegionalBedBoardVarianceRequiredCodeRule(message: "regional bed board variance needs this field"),
                RegionalBedBoardVarianceTitleLengthRule(maxLength: 32),
                RegionalBedBoardVarianceMarginRangeRule(min: 3.4, max: 2426.8),
                RegionalBedBoardVarianceWeightRangeRule(min: 7.4, max: 2467.1),
                RegionalBedBoardVarianceRequiredTitleRule(message: "regional bed board variance needs this field"),
            ]
        )
    }
}

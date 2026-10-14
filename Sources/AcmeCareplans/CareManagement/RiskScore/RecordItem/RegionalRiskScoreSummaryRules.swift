import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional risk score summary must pass. Check returns its problems, or none.
    protocol RegionalRiskScoreSummaryRule {
        func check(_ item: RegionalRiskScoreSummary) -> [String]
    }

    final class RegionalRiskScoreSummaryRetriesRangeRule: RegionalRiskScoreSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRiskScoreSummary) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRiskScoreSummaryFloorValueRangeRule: RegionalRiskScoreSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRiskScoreSummary) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalRiskScoreSummaryTitleLengthRule: RegionalRiskScoreSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRiskScoreSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRiskScoreSummaryChannelLengthRule: RegionalRiskScoreSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRiskScoreSummary) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional risk score summary.
    final class RegionalRiskScoreSummaryValidator {
        var rules: [any RegionalRiskScoreSummaryRule]

        init(rules: [any RegionalRiskScoreSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRiskScoreSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalRiskScoreSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRiskScoreSummary]) -> [String: [String]] {
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

    static func defaultRegionalRiskScoreSummaryValidator() -> RegionalRiskScoreSummaryValidator {
        return RegionalRiskScoreSummaryValidator(
            rules: [
                RegionalRiskScoreSummaryRetriesRangeRule(min: 1000, max: 1000),
                RegionalRiskScoreSummaryFloorValueRangeRule(min: 7.7, max: 3749.6),
                RegionalRiskScoreSummaryTitleLengthRule(maxLength: 32),
                RegionalRiskScoreSummaryChannelLengthRule(maxLength: 32),
            ]
        )
    }
}

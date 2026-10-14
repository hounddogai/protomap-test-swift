import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional rounding segment must pass. Check returns its problems, or none.
    protocol RegionalRoundingSegmentRule {
        func check(_ item: RegionalRoundingSegment) -> [String]
    }

    final class RegionalRoundingSegmentGraceDaysRangeRule: RegionalRoundingSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRoundingSegment) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalRoundingSegmentAttemptsRangeRule: RegionalRoundingSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRoundingSegment) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRoundingSegmentLimitRangeRule: RegionalRoundingSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRoundingSegment) -> [String] {
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

    final class RegionalRoundingSegmentRequiredCodeRule: RegionalRoundingSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRoundingSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional rounding segment.
    final class RegionalRoundingSegmentValidator {
        var rules: [any RegionalRoundingSegmentRule]

        init(rules: [any RegionalRoundingSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRoundingSegment) -> [String] {
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

        func requireValid(_ item: RegionalRoundingSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRoundingSegment]) -> [String: [String]] {
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

    static func defaultRegionalRoundingSegmentValidator() -> RegionalRoundingSegmentValidator {
        return RegionalRoundingSegmentValidator(
            rules: [
                RegionalRoundingSegmentGraceDaysRangeRule(min: 255, max: 86400),
                RegionalRoundingSegmentAttemptsRangeRule(min: 16, max: 120),
                RegionalRoundingSegmentLimitRangeRule(min: 255, max: 1000),
                RegionalRoundingSegmentRequiredCodeRule(message: "regional rounding segment needs a value"),
            ]
        )
    }
}

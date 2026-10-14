import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional overtime segment must pass. Check returns its problems, or none.
    protocol RegionalOvertimeSegmentRule {
        func check(_ item: RegionalOvertimeSegment) -> [String]
    }

    final class RegionalOvertimeSegmentCeilingRangeRule: RegionalOvertimeSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOvertimeSegment) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalOvertimeSegmentRequiredDescriptionRule: RegionalOvertimeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOvertimeSegment) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOvertimeSegmentDurationMinutesRangeRule: RegionalOvertimeSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOvertimeSegment) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalOvertimeSegmentRequiredLabelRule: RegionalOvertimeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOvertimeSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional overtime segment.
    final class RegionalOvertimeSegmentValidator {
        var rules: [any RegionalOvertimeSegmentRule]

        init(rules: [any RegionalOvertimeSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOvertimeSegment) -> [String] {
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

        func requireValid(_ item: RegionalOvertimeSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOvertimeSegment]) -> [String: [String]] {
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

    static func defaultRegionalOvertimeSegmentValidator() -> RegionalOvertimeSegmentValidator {
        return RegionalOvertimeSegmentValidator(
            rules: [
                RegionalOvertimeSegmentCeilingRangeRule(min: 0.8, max: 815.1),
                RegionalOvertimeSegmentRequiredDescriptionRule(message: "regional overtime segment needs an entry"),
                RegionalOvertimeSegmentDurationMinutesRangeRule(min: 32, max: 80),
                RegionalOvertimeSegmentRequiredLabelRule(message: "regional overtime segment needs an entry"),
            ]
        )
    }
}

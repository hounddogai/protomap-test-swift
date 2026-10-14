import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift segment must pass. Check returns its problems, or none.
    protocol ShiftSegmentRule {
        func check(_ item: ShiftSegment) -> [String]
    }

    final class ShiftSegmentBudgetRangeRule: ShiftSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftSegment) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftSegmentRequiredLocaleRule: ShiftSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftSegment) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftSegmentCodeLengthRule: ShiftSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftSegmentWindowDaysRangeRule: ShiftSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftSegment) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a shift segment.
    final class ShiftSegmentValidator {
        var rules: [any ShiftSegmentRule]

        init(rules: [any ShiftSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftSegment) -> [String] {
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

        func requireValid(_ item: ShiftSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftSegment]) -> [String: [String]] {
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

    static func defaultShiftSegmentValidator() -> ShiftSegmentValidator {
        return ShiftSegmentValidator(
            rules: [
                ShiftSegmentBudgetRangeRule(min: 5.6, max: 613.6),
                ShiftSegmentRequiredLocaleRule(message: "shift segment needs a value"),
                ShiftSegmentCodeLengthRule(maxLength: 80),
                ShiftSegmentWindowDaysRangeRule(min: 80, max: 86400),
            ]
        )
    }
}

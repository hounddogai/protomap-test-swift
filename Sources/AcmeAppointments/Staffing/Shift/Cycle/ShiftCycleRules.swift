import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift cycle must pass. Check returns its problems, or none.
    protocol ShiftCycleRule {
        func check(_ item: ShiftCycle) -> [String]
    }

    final class ShiftCycleCopayRangeRule: ShiftCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftCycle) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftCycleRequiredCodeRule: ShiftCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftCycleReviewerLengthRule: ShiftCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftCycle) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftCycleRequiredNotesRule: ShiftCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftCycle) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftCycleNameLengthRule: ShiftCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift cycle.
    final class ShiftCycleValidator {
        var rules: [any ShiftCycleRule]

        init(rules: [any ShiftCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftCycle]) -> [String: [String]] {
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

    static func defaultShiftCycleValidator() -> ShiftCycleValidator {
        return ShiftCycleValidator(
            rules: [
                ShiftCycleCopayRangeRule(min: 7.4, max: 4809.0),
                ShiftCycleRequiredCodeRule(message: "shift cycle needs an entry"),
                ShiftCycleReviewerLengthRule(maxLength: 120),
                ShiftCycleRequiredNotesRule(message: "shift cycle needs a value"),
                ShiftCycleNameLengthRule(maxLength: 255),
            ]
        )
    }
}

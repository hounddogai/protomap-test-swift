import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift group must pass. Check returns its problems, or none.
    protocol ShiftGroupRule {
        func check(_ item: ShiftGroup) -> [String]
    }

    final class ShiftGroupExternalRefLengthRule: ShiftGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftGroup) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftGroupCapacityRangeRule: ShiftGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftGroup) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftGroupExpiresAtRangeRule: ShiftGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftGroup) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftGroupCodeLengthRule: ShiftGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftGroupReviewerLengthRule: ShiftGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftGroup) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift group.
    final class ShiftGroupValidator {
        var rules: [any ShiftGroupRule]

        init(rules: [any ShiftGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftGroup]) -> [String: [String]] {
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

    static func defaultShiftGroupValidator() -> ShiftGroupValidator {
        return ShiftGroupValidator(
            rules: [
                ShiftGroupExternalRefLengthRule(maxLength: 32),
                ShiftGroupCapacityRangeRule(min: 64, max: 86400),
                ShiftGroupExpiresAtRangeRule(min: 255, max: 3600),
                ShiftGroupCodeLengthRule(maxLength: 80),
                ShiftGroupReviewerLengthRule(maxLength: 64),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted claim assignment must pass. Check returns its problems, or none.
    protocol WeightedClaimAssignmentRule {
        func check(_ item: WeightedClaimAssignment) -> [String]
    }

    final class WeightedClaimAssignmentWardLengthRule: WeightedClaimAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedClaimAssignment) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedClaimAssignmentRequiredCodeRule: WeightedClaimAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedClaimAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedClaimAssignmentWindowDaysRangeRule: WeightedClaimAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedClaimAssignment) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedClaimAssignmentCodeLengthRule: WeightedClaimAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedClaimAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedClaimAssignmentRequiredWardRule: WeightedClaimAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedClaimAssignment) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedClaimAssignmentDiscountRangeRule: WeightedClaimAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedClaimAssignment) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted claim assignment.
    final class WeightedClaimAssignmentValidator {
        var rules: [any WeightedClaimAssignmentRule]

        init(rules: [any WeightedClaimAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedClaimAssignment) -> [String] {
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

        func requireValid(_ item: WeightedClaimAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedClaimAssignment]) -> [String: [String]] {
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

    static func defaultWeightedClaimAssignmentValidator() -> WeightedClaimAssignmentValidator {
        return WeightedClaimAssignmentValidator(
            rules: [
                WeightedClaimAssignmentWardLengthRule(maxLength: 1000),
                WeightedClaimAssignmentRequiredCodeRule(message: "weighted claim assignment needs a value"),
                WeightedClaimAssignmentWindowDaysRangeRule(min: 32, max: 80),
                WeightedClaimAssignmentCodeLengthRule(maxLength: 80),
                WeightedClaimAssignmentRequiredWardRule(message: "weighted claim assignment needs this field"),
                WeightedClaimAssignmentDiscountRangeRule(min: 7.4, max: 2959.1),
            ]
        )
    }
}

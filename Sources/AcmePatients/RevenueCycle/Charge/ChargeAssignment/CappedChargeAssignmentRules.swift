import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped charge assignment must pass. Check returns its problems, or none.
    protocol CappedChargeAssignmentRule {
        func check(_ item: CappedChargeAssignment) -> [String]
    }

    final class CappedChargeAssignmentCodeLengthRule: CappedChargeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedChargeAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedChargeAssignmentAllowedLabelRule: CappedChargeAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedChargeAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class CappedChargeAssignmentWeightRangeRule: CappedChargeAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedChargeAssignment) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedChargeAssignmentCostRangeRule: CappedChargeAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedChargeAssignment) -> [String] {
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

    /// Runs every rule of a capped charge assignment.
    final class CappedChargeAssignmentValidator {
        var rules: [any CappedChargeAssignmentRule]

        init(rules: [any CappedChargeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedChargeAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedChargeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedChargeAssignment]) -> [String: [String]] {
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

    static func defaultCappedChargeAssignmentValidator() -> CappedChargeAssignmentValidator {
        return CappedChargeAssignmentValidator(
            rules: [
                CappedChargeAssignmentCodeLengthRule(maxLength: 3600),
                CappedChargeAssignmentAllowedLabelRule(allowed: ["regional", "capped", "tiered"]),
                CappedChargeAssignmentWeightRangeRule(min: 5.3, max: 1395.5),
                CappedChargeAssignmentCostRangeRule(min: 6.0, max: 190.0),
            ]
        )
    }
}

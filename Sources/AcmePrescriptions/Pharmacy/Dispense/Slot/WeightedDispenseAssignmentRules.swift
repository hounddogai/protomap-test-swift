import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted dispense assignment must pass. Check returns its problems, or none.
    protocol WeightedDispenseAssignmentRule {
        func check(_ item: WeightedDispenseAssignment) -> [String]
    }

    final class WeightedDispenseAssignmentRetriesRangeRule: WeightedDispenseAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedDispenseAssignment) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedDispenseAssignmentLabelLengthRule: WeightedDispenseAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDispenseAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDispenseAssignmentRequiredBedRule: WeightedDispenseAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDispenseAssignment) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedDispenseAssignmentAllowedBedRule: WeightedDispenseAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedDispenseAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted dispense assignment.
    final class WeightedDispenseAssignmentValidator {
        var rules: [any WeightedDispenseAssignmentRule]

        init(rules: [any WeightedDispenseAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDispenseAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedDispenseAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDispenseAssignment]) -> [String: [String]] {
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

    static func defaultWeightedDispenseAssignmentValidator() -> WeightedDispenseAssignmentValidator {
        return WeightedDispenseAssignmentValidator(
            rules: [
                WeightedDispenseAssignmentRetriesRangeRule(min: 16, max: 120),
                WeightedDispenseAssignmentLabelLengthRule(maxLength: 1000),
                WeightedDispenseAssignmentRequiredBedRule(message: "weighted dispense assignment needs an entry"),
                WeightedDispenseAssignmentAllowedBedRule(allowed: []),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set assignment must pass. Check returns its problems, or none.
    protocol OrderSetAssignmentRule {
        func check(_ item: OrderSetAssignment) -> [String]
    }

    final class OrderSetAssignmentRequiredLocaleRule: OrderSetAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetAssignment) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetAssignmentLimitRangeRule: OrderSetAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetAssignment) -> [String] {
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

    final class OrderSetAssignmentRequiredNameRule: OrderSetAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetAssignmentDosageMgRangeRule: OrderSetAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetAssignment) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a order set assignment.
    final class OrderSetAssignmentValidator {
        var rules: [any OrderSetAssignmentRule]

        init(rules: [any OrderSetAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetAssignment) -> [String] {
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

        func requireValid(_ item: OrderSetAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetAssignment]) -> [String: [String]] {
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

    static func defaultOrderSetAssignmentValidator() -> OrderSetAssignmentValidator {
        return OrderSetAssignmentValidator(
            rules: [
                OrderSetAssignmentRequiredLocaleRule(message: "order set assignment needs a value"),
                OrderSetAssignmentLimitRangeRule(min: 16, max: 255),
                OrderSetAssignmentRequiredNameRule(message: "order set assignment needs an entry"),
                OrderSetAssignmentDosageMgRangeRule(min: 2.0, max: 3045.7),
            ]
        )
    }
}

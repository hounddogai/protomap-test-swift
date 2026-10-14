import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory assignment must pass. Check returns its problems, or none.
    protocol InventoryAssignmentRule {
        func check(_ item: InventoryAssignment) -> [String]
    }

    final class InventoryAssignmentRequiredBedRule: InventoryAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAssignment) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryAssignmentBedLengthRule: InventoryAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryAssignment) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryAssignmentRequiredSummaryRule: InventoryAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAssignment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryAssignmentRequiredCodeRule: InventoryAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory assignment.
    final class InventoryAssignmentValidator {
        var rules: [any InventoryAssignmentRule]

        init(rules: [any InventoryAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryAssignment]) -> [String: [String]] {
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

    static func defaultInventoryAssignmentValidator() -> InventoryAssignmentValidator {
        return InventoryAssignmentValidator(
            rules: [
                InventoryAssignmentRequiredBedRule(message: "inventory assignment needs this field"),
                InventoryAssignmentBedLengthRule(maxLength: 1000),
                InventoryAssignmentRequiredSummaryRule(message: "inventory assignment needs an entry"),
                InventoryAssignmentRequiredCodeRule(message: "inventory assignment needs an entry"),
            ]
        )
    }
}

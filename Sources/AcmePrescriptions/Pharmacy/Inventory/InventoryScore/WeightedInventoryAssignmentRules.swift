import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted inventory assignment must pass. Check returns its problems, or none.
    protocol WeightedInventoryAssignmentRule {
        func check(_ item: WeightedInventoryAssignment) -> [String]
    }

    final class WeightedInventoryAssignmentCodePrefixRule: WeightedInventoryAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedInventoryAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedInventoryAssignmentRequiredCodeRule: WeightedInventoryAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInventoryAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedInventoryAssignmentRequiredEncounterIDRule: WeightedInventoryAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInventoryAssignment) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted inventory assignment.
    final class WeightedInventoryAssignmentValidator {
        var rules: [any WeightedInventoryAssignmentRule]

        init(rules: [any WeightedInventoryAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedInventoryAssignment) -> [String] {
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

        func requireValid(_ item: WeightedInventoryAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedInventoryAssignment]) -> [String: [String]] {
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

    static func defaultWeightedInventoryAssignmentValidator() -> WeightedInventoryAssignmentValidator {
        return WeightedInventoryAssignmentValidator(
            rules: [
                WeightedInventoryAssignmentCodePrefixRule(prefix: "ACM"),
                WeightedInventoryAssignmentRequiredCodeRule(message: "weighted inventory assignment needs an entry"),
                WeightedInventoryAssignmentRequiredEncounterIDRule(
                    message: "weighted inventory assignment needs an entry"
                ),
            ]
        )
    }
}

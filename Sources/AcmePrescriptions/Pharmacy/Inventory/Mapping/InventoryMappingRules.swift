import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory mapping must pass. Check returns its problems, or none.
    protocol InventoryMappingRule {
        func check(_ item: InventoryMapping) -> [String]
    }

    final class InventoryMappingRefillsRangeRule: InventoryMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryMapping) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryMappingStartsAtRangeRule: InventoryMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryMapping) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryMappingArchivedGuardRule: InventoryMappingRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: InventoryMapping) -> [String] {
            if item.archived && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class InventoryMappingRequiredNotesRule: InventoryMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryMapping) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory mapping.
    final class InventoryMappingValidator {
        var rules: [any InventoryMappingRule]

        init(rules: [any InventoryMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryMapping]) -> [String: [String]] {
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

    static func defaultInventoryMappingValidator() -> InventoryMappingValidator {
        return InventoryMappingValidator(
            rules: [
                InventoryMappingRefillsRangeRule(min: 120, max: 1000),
                InventoryMappingStartsAtRangeRule(min: 255, max: 86400),
                InventoryMappingArchivedGuardRule(limit: 86400),
                InventoryMappingRequiredNotesRule(message: "inventory mapping needs an entry"),
            ]
        )
    }
}

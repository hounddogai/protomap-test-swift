import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory entry must pass. Check returns its problems, or none.
    protocol InventoryEntryRule {
        func check(_ item: InventoryEntry) -> [String]
    }

    final class InventoryEntryRequiredCategoryRule: InventoryEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryEntry) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryEntryCategoryLengthRule: InventoryEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryEntry) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryEntryAllowedClinicianIDRule: InventoryEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is above maximum"]
            }
            return []
        }
    }

    final class InventoryEntryRefillsRangeRule: InventoryEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryEntry) -> [String] {
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

    final class InventoryEntryRequiredClinicianIDRule: InventoryEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryEntry) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryEntryRatioRangeRule: InventoryEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryEntry) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a inventory entry.
    final class InventoryEntryValidator {
        var rules: [any InventoryEntryRule]

        init(rules: [any InventoryEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryEntry]) -> [String: [String]] {
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

    static func defaultInventoryEntryValidator() -> InventoryEntryValidator {
        return InventoryEntryValidator(
            rules: [
                InventoryEntryRequiredCategoryRule(message: "inventory entry needs this field"),
                InventoryEntryCategoryLengthRule(maxLength: 86400),
                InventoryEntryAllowedClinicianIDRule(allowed: ["adaptive", "batched", "pending"]),
                InventoryEntryRefillsRangeRule(min: 80, max: 3600),
                InventoryEntryRequiredClinicianIDRule(message: "inventory entry needs an entry"),
                InventoryEntryRatioRangeRule(min: 2.0, max: 750.1),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory claim must pass. Check returns its problems, or none.
    protocol InventoryClaimRule {
        func check(_ item: InventoryClaim) -> [String]
    }

    final class InventoryClaimCeilingRangeRule: InventoryClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryClaim) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryClaimCreatedAtRangeRule: InventoryClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryClaim) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryClaimNotesLengthRule: InventoryClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryClaim) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryClaimCodeLengthRule: InventoryClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryClaimCodePrefixRule: InventoryClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryClaimRequiredCodeRule: InventoryClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory claim.
    final class InventoryClaimValidator {
        var rules: [any InventoryClaimRule]

        init(rules: [any InventoryClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryClaim]) -> [String: [String]] {
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

    static func defaultInventoryClaimValidator() -> InventoryClaimValidator {
        return InventoryClaimValidator(
            rules: [
                InventoryClaimCeilingRangeRule(min: 8.6, max: 4603.2),
                InventoryClaimCreatedAtRangeRule(min: 1000, max: 86400),
                InventoryClaimNotesLengthRule(maxLength: 120),
                InventoryClaimCodeLengthRule(maxLength: 255),
                InventoryClaimCodePrefixRule(prefix: "ACM"),
                InventoryClaimRequiredCodeRule(message: "inventory claim needs an entry"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory summary must pass. Check returns its problems, or none.
    protocol InventorySummaryRule {
        func check(_ item: InventorySummary) -> [String]
    }

    final class InventorySummaryCodePrefixRule: InventorySummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventorySummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventorySummaryEndsAtRangeRule: InventorySummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventorySummary) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventorySummaryRequiredCodeRule: InventorySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventorySummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventorySummaryAllowedNameRule: InventorySummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventorySummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class InventorySummaryRequiredNameRule: InventorySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventorySummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventorySummaryQuantityRangeRule: InventorySummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventorySummary) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a inventory summary.
    final class InventorySummaryValidator {
        var rules: [any InventorySummaryRule]

        init(rules: [any InventorySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: InventorySummary) -> [String] {
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

        func requireValid(_ item: InventorySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventorySummary]) -> [String: [String]] {
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

    static func defaultInventorySummaryValidator() -> InventorySummaryValidator {
        return InventorySummaryValidator(
            rules: [
                InventorySummaryCodePrefixRule(prefix: "OPS"),
                InventorySummaryEndsAtRangeRule(min: 255, max: 86400),
                InventorySummaryRequiredCodeRule(message: "inventory summary needs an entry"),
                InventorySummaryAllowedNameRule(allowed: []),
                InventorySummaryRequiredNameRule(message: "inventory summary needs a value"),
                InventorySummaryQuantityRangeRule(min: 80, max: 120),
            ]
        )
    }
}

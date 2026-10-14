import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory bundle must pass. Check returns its problems, or none.
    protocol InventoryBundleRule {
        func check(_ item: InventoryBundle) -> [String]
    }

    final class InventoryBundleVersionRangeRule: InventoryBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryBundle) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryBundleMaximumRangeRule: InventoryBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryBundle) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryBundleRequiredTitleRule: InventoryBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory bundle.
    final class InventoryBundleValidator {
        var rules: [any InventoryBundleRule]

        init(rules: [any InventoryBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryBundle) -> [String] {
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

        func requireValid(_ item: InventoryBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryBundle]) -> [String: [String]] {
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

    static func defaultInventoryBundleValidator() -> InventoryBundleValidator {
        return InventoryBundleValidator(
            rules: [
                InventoryBundleVersionRangeRule(min: 16, max: 80),
                InventoryBundleMaximumRangeRule(min: 5.0, max: 893.9),
                InventoryBundleRequiredTitleRule(message: "inventory bundle needs an entry"),
            ]
        )
    }
}

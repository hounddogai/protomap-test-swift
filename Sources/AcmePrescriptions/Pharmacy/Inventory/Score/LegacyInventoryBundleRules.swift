import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy inventory bundle must pass. Check returns its problems, or none.
    protocol LegacyInventoryBundleRule {
        func check(_ item: LegacyInventoryBundle) -> [String]
    }

    final class LegacyInventoryBundleRequiredAllergyRule: LegacyInventoryBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInventoryBundle) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInventoryBundleAllowedAllergyRule: LegacyInventoryBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyInventoryBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is blocked"]
            }
            return []
        }
    }

    final class LegacyInventoryBundleAmountRangeRule: LegacyInventoryBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyInventoryBundle) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyInventoryBundleLabelLengthRule: LegacyInventoryBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInventoryBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyInventoryBundleRequiredLabelRule: LegacyInventoryBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInventoryBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInventoryBundleCostRangeRule: LegacyInventoryBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyInventoryBundle) -> [String] {
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

    /// Runs every rule of a legacy inventory bundle.
    final class LegacyInventoryBundleValidator {
        var rules: [any LegacyInventoryBundleRule]

        init(rules: [any LegacyInventoryBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyInventoryBundle) -> [String] {
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

        func requireValid(_ item: LegacyInventoryBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyInventoryBundle]) -> [String: [String]] {
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

    static func defaultLegacyInventoryBundleValidator() -> LegacyInventoryBundleValidator {
        return LegacyInventoryBundleValidator(
            rules: [
                LegacyInventoryBundleRequiredAllergyRule(message: "legacy inventory bundle needs a value"),
                LegacyInventoryBundleAllowedAllergyRule(allowed: ["strict", "adaptive"]),
                LegacyInventoryBundleAmountRangeRule(min: 2.6, max: 3955.6),
                LegacyInventoryBundleLabelLengthRule(maxLength: 120),
                LegacyInventoryBundleRequiredLabelRule(message: "legacy inventory bundle needs an entry"),
                LegacyInventoryBundleCostRangeRule(min: 3.7, max: 1575.1),
            ]
        )
    }
}

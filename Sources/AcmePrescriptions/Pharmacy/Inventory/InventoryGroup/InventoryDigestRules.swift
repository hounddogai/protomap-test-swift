import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory digest must pass. Check returns its problems, or none.
    protocol InventoryDigestRule {
        func check(_ item: InventoryDigest) -> [String]
    }

    final class InventoryDigestCurrencyLengthRule: InventoryDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryDigest) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryDigestRequiredCurrencyRule: InventoryDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryDigest) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryDigestCodeLengthRule: InventoryDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryDigestAllowedTitleRule: InventoryDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class InventoryDigestWeightRangeRule: InventoryDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryDigest) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a inventory digest.
    final class InventoryDigestValidator {
        var rules: [any InventoryDigestRule]

        init(rules: [any InventoryDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryDigest]) -> [String: [String]] {
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

    static func defaultInventoryDigestValidator() -> InventoryDigestValidator {
        return InventoryDigestValidator(
            rules: [
                InventoryDigestCurrencyLengthRule(maxLength: 16),
                InventoryDigestRequiredCurrencyRule(message: "inventory digest needs this field"),
                InventoryDigestCodeLengthRule(maxLength: 64),
                InventoryDigestAllowedTitleRule(allowed: ["seasonal", "seasonal", "default"]),
                InventoryDigestWeightRangeRule(min: 5.6, max: 4217.8),
            ]
        )
    }
}

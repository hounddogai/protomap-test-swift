import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure estimate must pass. Check returns its problems, or none.
    protocol DisclosureEstimateRule {
        func check(_ item: DisclosureEstimate) -> [String]
    }

    final class DisclosureEstimateMaximumRangeRule: DisclosureEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureEstimate) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureEstimateRequiredDescriptionRule: DisclosureEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureEstimate) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureEstimateRequiredCodeRule: DisclosureEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureEstimateAllowedSpecialtyRule: DisclosureEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is blocked"]
            }
            return []
        }
    }

    final class DisclosureEstimateAmountRangeRule: DisclosureEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureEstimate) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureEstimateCodeLengthRule: DisclosureEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure estimate.
    final class DisclosureEstimateValidator {
        var rules: [any DisclosureEstimateRule]

        init(rules: [any DisclosureEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureEstimate) -> [String] {
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

        func requireValid(_ item: DisclosureEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureEstimate]) -> [String: [String]] {
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

    static func defaultDisclosureEstimateValidator() -> DisclosureEstimateValidator {
        return DisclosureEstimateValidator(
            rules: [
                DisclosureEstimateMaximumRangeRule(min: 4.9, max: 1443.9),
                DisclosureEstimateRequiredDescriptionRule(message: "disclosure estimate needs a value"),
                DisclosureEstimateRequiredCodeRule(message: "disclosure estimate needs an entry"),
                DisclosureEstimateAllowedSpecialtyRule(allowed: []),
                DisclosureEstimateAmountRangeRule(min: 2.0, max: 2585.7),
                DisclosureEstimateCodeLengthRule(maxLength: 64),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted modality tier must pass. Check returns its problems, or none.
    protocol WeightedModalityTierRule {
        func check(_ item: WeightedModalityTier) -> [String]
    }

    final class WeightedModalityTierCopayRangeRule: WeightedModalityTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedModalityTier) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedModalityTierAllowedNameRule: WeightedModalityTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedModalityTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class WeightedModalityTierNameLengthRule: WeightedModalityTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedModalityTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedModalityTierCodeLengthRule: WeightedModalityTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedModalityTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedModalityTierRequiredUnitRule: WeightedModalityTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedModalityTier) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted modality tier.
    final class WeightedModalityTierValidator {
        var rules: [any WeightedModalityTierRule]

        init(rules: [any WeightedModalityTierRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedModalityTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedModalityTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedModalityTier]) -> [String: [String]] {
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

    static func defaultWeightedModalityTierValidator() -> WeightedModalityTierValidator {
        return WeightedModalityTierValidator(
            rules: [
                WeightedModalityTierCopayRangeRule(min: 2.0, max: 1620.1),
                WeightedModalityTierAllowedNameRule(allowed: ["fallback", "weighted"]),
                WeightedModalityTierNameLengthRule(maxLength: 120),
                WeightedModalityTierCodeLengthRule(maxLength: 255),
                WeightedModalityTierRequiredUnitRule(message: "weighted modality tier needs an entry"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding tier must pass. Check returns its problems, or none.
    protocol RoundingTierRule {
        func check(_ item: RoundingTier) -> [String]
    }

    final class RoundingTierRequiredNameRule: RoundingTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingTierRequiredTimezoneRule: RoundingTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingTier) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingTierNameLengthRule: RoundingTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingTierRequiredCodeRule: RoundingTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingTierThresholdRangeRule: RoundingTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingTier) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rounding tier.
    final class RoundingTierValidator {
        var rules: [any RoundingTierRule]

        init(rules: [any RoundingTierRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingTier) -> [String] {
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

        func requireValid(_ item: RoundingTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingTier]) -> [String: [String]] {
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

    static func defaultRoundingTierValidator() -> RoundingTierValidator {
        return RoundingTierValidator(
            rules: [
                RoundingTierRequiredNameRule(message: "rounding tier needs this field"),
                RoundingTierRequiredTimezoneRule(message: "rounding tier needs an entry"),
                RoundingTierNameLengthRule(maxLength: 3600),
                RoundingTierRequiredCodeRule(message: "rounding tier needs an entry"),
                RoundingTierThresholdRangeRule(min: 1.9, max: 2490.8),
            ]
        )
    }
}

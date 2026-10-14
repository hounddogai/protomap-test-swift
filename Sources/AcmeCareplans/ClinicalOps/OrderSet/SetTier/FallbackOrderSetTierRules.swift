import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback order set tier must pass. Check returns its problems, or none.
    protocol FallbackOrderSetTierRule {
        func check(_ item: FallbackOrderSetTier) -> [String]
    }

    final class FallbackOrderSetTierCountryLengthRule: FallbackOrderSetTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOrderSetTier) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackOrderSetTierRequiredBedRule: FallbackOrderSetTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetTier) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOrderSetTierStartsAtRangeRule: FallbackOrderSetTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackOrderSetTier) -> [String] {
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

    final class FallbackOrderSetTierRequiredCodeRule: FallbackOrderSetTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOrderSetTierRequiredCountryRule: FallbackOrderSetTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetTier) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback order set tier.
    final class FallbackOrderSetTierValidator {
        var rules: [any FallbackOrderSetTierRule]

        init(rules: [any FallbackOrderSetTierRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOrderSetTier) -> [String] {
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

        func requireValid(_ item: FallbackOrderSetTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOrderSetTier]) -> [String: [String]] {
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

    static func defaultFallbackOrderSetTierValidator() -> FallbackOrderSetTierValidator {
        return FallbackOrderSetTierValidator(
            rules: [
                FallbackOrderSetTierCountryLengthRule(maxLength: 255),
                FallbackOrderSetTierRequiredBedRule(message: "fallback order set tier needs a value"),
                FallbackOrderSetTierStartsAtRangeRule(min: 32, max: 1000),
                FallbackOrderSetTierRequiredCodeRule(message: "fallback order set tier needs a value"),
                FallbackOrderSetTierRequiredCountryRule(message: "fallback order set tier needs a value"),
            ]
        )
    }
}

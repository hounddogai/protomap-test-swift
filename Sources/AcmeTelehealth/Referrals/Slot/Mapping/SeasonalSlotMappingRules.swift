import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal slot mapping must pass. Check returns its problems, or none.
    protocol SeasonalSlotMappingRule {
        func check(_ item: SeasonalSlotMapping) -> [String]
    }

    final class SeasonalSlotMappingRequiredNameRule: SeasonalSlotMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSlotMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSlotMappingNameLengthRule: SeasonalSlotMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSlotMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSlotMappingCurrencyLengthRule: SeasonalSlotMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSlotMapping) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSlotMappingAllowedCurrencyRule: SeasonalSlotMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSlotMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalSlotMappingEndsAtRangeRule: SeasonalSlotMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSlotMapping) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal slot mapping.
    final class SeasonalSlotMappingValidator {
        var rules: [any SeasonalSlotMappingRule]

        init(rules: [any SeasonalSlotMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSlotMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSlotMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSlotMapping]) -> [String: [String]] {
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

    static func defaultSeasonalSlotMappingValidator() -> SeasonalSlotMappingValidator {
        return SeasonalSlotMappingValidator(
            rules: [
                SeasonalSlotMappingRequiredNameRule(message: "seasonal slot mapping needs an entry"),
                SeasonalSlotMappingNameLengthRule(maxLength: 255),
                SeasonalSlotMappingCurrencyLengthRule(maxLength: 64),
                SeasonalSlotMappingAllowedCurrencyRule(allowed: ["fallback"]),
                SeasonalSlotMappingEndsAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal inventory target must pass. Check returns its problems, or none.
    protocol SeasonalInventoryTargetRule {
        func check(_ item: SeasonalInventoryTarget) -> [String]
    }

    final class SeasonalInventoryTargetCodeLengthRule: SeasonalInventoryTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalInventoryTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalInventoryTargetRequiredCodeRule: SeasonalInventoryTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInventoryTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInventoryTargetUpdatedAtRangeRule: SeasonalInventoryTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalInventoryTarget) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalInventoryTargetMaximumRangeRule: SeasonalInventoryTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalInventoryTarget) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalInventoryTargetCodePrefixRule: SeasonalInventoryTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalInventoryTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal inventory target.
    final class SeasonalInventoryTargetValidator {
        var rules: [any SeasonalInventoryTargetRule]

        init(rules: [any SeasonalInventoryTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalInventoryTarget) -> [String] {
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

        func requireValid(_ item: SeasonalInventoryTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalInventoryTarget]) -> [String: [String]] {
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

    static func defaultSeasonalInventoryTargetValidator() -> SeasonalInventoryTargetValidator {
        return SeasonalInventoryTargetValidator(
            rules: [
                SeasonalInventoryTargetCodeLengthRule(maxLength: 16),
                SeasonalInventoryTargetRequiredCodeRule(message: "seasonal inventory target needs an entry"),
                SeasonalInventoryTargetUpdatedAtRangeRule(min: 32, max: 3600),
                SeasonalInventoryTargetMaximumRangeRule(min: 4.3, max: 318.0),
                SeasonalInventoryTargetCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}

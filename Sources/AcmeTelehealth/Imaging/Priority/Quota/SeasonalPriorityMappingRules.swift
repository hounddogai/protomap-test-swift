import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal priority mapping must pass. Check returns its problems, or none.
    protocol SeasonalPriorityMappingRule {
        func check(_ item: SeasonalPriorityMapping) -> [String]
    }

    final class SeasonalPriorityMappingRequiredNameRule: SeasonalPriorityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalPriorityMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalPriorityMappingChannelLengthRule: SeasonalPriorityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPriorityMapping) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalPriorityMappingDiscountRangeRule: SeasonalPriorityMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalPriorityMapping) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalPriorityMappingCreatedAtRangeRule: SeasonalPriorityMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalPriorityMapping) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal priority mapping.
    final class SeasonalPriorityMappingValidator {
        var rules: [any SeasonalPriorityMappingRule]

        init(rules: [any SeasonalPriorityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalPriorityMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalPriorityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalPriorityMapping]) -> [String: [String]] {
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

    static func defaultSeasonalPriorityMappingValidator() -> SeasonalPriorityMappingValidator {
        return SeasonalPriorityMappingValidator(
            rules: [
                SeasonalPriorityMappingRequiredNameRule(message: "seasonal priority mapping needs a value"),
                SeasonalPriorityMappingChannelLengthRule(maxLength: 32),
                SeasonalPriorityMappingDiscountRangeRule(min: 5.4, max: 3636.5),
                SeasonalPriorityMappingCreatedAtRangeRule(min: 80, max: 120),
            ]
        )
    }
}

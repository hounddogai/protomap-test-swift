import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal care gap threshold must pass. Check returns its problems, or none.
    protocol SeasonalCareGapThresholdRule {
        func check(_ item: SeasonalCareGapThreshold) -> [String]
    }

    final class SeasonalCareGapThresholdCostRangeRule: SeasonalCareGapThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapThreshold) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCareGapThresholdNameLengthRule: SeasonalCareGapThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareGapThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCareGapThresholdSequenceRangeRule: SeasonalCareGapThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapThreshold) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCareGapThresholdCreatedAtRangeRule: SeasonalCareGapThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapThreshold) -> [String] {
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

    final class SeasonalCareGapThresholdRequiredCodeRule: SeasonalCareGapThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareGapThresholdCodePrefixRule: SeasonalCareGapThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalCareGapThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal care gap threshold.
    final class SeasonalCareGapThresholdValidator {
        var rules: [any SeasonalCareGapThresholdRule]

        init(rules: [any SeasonalCareGapThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareGapThreshold) -> [String] {
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

        func requireValid(_ item: SeasonalCareGapThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareGapThreshold]) -> [String: [String]] {
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

    static func defaultSeasonalCareGapThresholdValidator() -> SeasonalCareGapThresholdValidator {
        return SeasonalCareGapThresholdValidator(
            rules: [
                SeasonalCareGapThresholdCostRangeRule(min: 5.8, max: 2401.1),
                SeasonalCareGapThresholdNameLengthRule(maxLength: 255),
                SeasonalCareGapThresholdSequenceRangeRule(min: 32, max: 64),
                SeasonalCareGapThresholdCreatedAtRangeRule(min: 120, max: 1000),
                SeasonalCareGapThresholdRequiredCodeRule(message: "seasonal care gap threshold needs a value"),
                SeasonalCareGapThresholdCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}

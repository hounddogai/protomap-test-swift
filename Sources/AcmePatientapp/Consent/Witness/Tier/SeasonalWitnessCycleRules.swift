import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal witness cycle must pass. Check returns its problems, or none.
    protocol SeasonalWitnessCycleRule {
        func check(_ item: SeasonalWitnessCycle) -> [String]
    }

    final class SeasonalWitnessCycleRequiredWardRule: SeasonalWitnessCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWitnessCycle) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalWitnessCycleActiveGuardRule: SeasonalWitnessCycleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SeasonalWitnessCycle) -> [String] {
            if item.active && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class SeasonalWitnessCycleRequiredLabelRule: SeasonalWitnessCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWitnessCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalWitnessCycleRatioRangeRule: SeasonalWitnessCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalWitnessCycle) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalWitnessCycleLabelLengthRule: SeasonalWitnessCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWitnessCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWitnessCycleCodeLengthRule: SeasonalWitnessCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWitnessCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal witness cycle.
    final class SeasonalWitnessCycleValidator {
        var rules: [any SeasonalWitnessCycleRule]

        init(rules: [any SeasonalWitnessCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalWitnessCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalWitnessCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalWitnessCycle]) -> [String: [String]] {
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

    static func defaultSeasonalWitnessCycleValidator() -> SeasonalWitnessCycleValidator {
        return SeasonalWitnessCycleValidator(
            rules: [
                SeasonalWitnessCycleRequiredWardRule(message: "seasonal witness cycle needs this field"),
                SeasonalWitnessCycleActiveGuardRule(limit: 2.9),
                SeasonalWitnessCycleRequiredLabelRule(message: "seasonal witness cycle needs a value"),
                SeasonalWitnessCycleRatioRangeRule(min: 2.0, max: 2759.4),
                SeasonalWitnessCycleLabelLengthRule(maxLength: 64),
                SeasonalWitnessCycleCodeLengthRule(maxLength: 64),
            ]
        )
    }
}

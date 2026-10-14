import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal closure checkpoint must pass. Check returns its problems, or none.
    protocol SeasonalClosureCheckpointRule {
        func check(_ item: SeasonalClosureCheckpoint) -> [String]
    }

    final class SeasonalClosureCheckpointTitleLengthRule: SeasonalClosureCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalClosureCheckpointWindowDaysRangeRule: SeasonalClosureCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalClosureCheckpoint) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalClosureCheckpointRequiredTitleRule: SeasonalClosureCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureCheckpointRequiredWardRule: SeasonalClosureCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureCheckpoint) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalClosureCheckpointWardLengthRule: SeasonalClosureCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureCheckpoint) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal closure checkpoint.
    final class SeasonalClosureCheckpointValidator {
        var rules: [any SeasonalClosureCheckpointRule]

        init(rules: [any SeasonalClosureCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalClosureCheckpoint) -> [String] {
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

        func requireValid(_ item: SeasonalClosureCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalClosureCheckpoint]) -> [String: [String]] {
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

    static func defaultSeasonalClosureCheckpointValidator() -> SeasonalClosureCheckpointValidator {
        return SeasonalClosureCheckpointValidator(
            rules: [
                SeasonalClosureCheckpointTitleLengthRule(maxLength: 120),
                SeasonalClosureCheckpointWindowDaysRangeRule(min: 120, max: 86400),
                SeasonalClosureCheckpointRequiredTitleRule(message: "seasonal closure checkpoint needs an entry"),
                SeasonalClosureCheckpointRequiredWardRule(message: "seasonal closure checkpoint needs this field"),
                SeasonalClosureCheckpointWardLengthRule(maxLength: 16),
            ]
        )
    }
}

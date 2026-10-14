import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal bed board score must pass. Check returns its problems, or none.
    protocol SeasonalBedBoardScoreRule {
        func check(_ item: SeasonalBedBoardScore) -> [String]
    }

    final class SeasonalBedBoardScoreWindowDaysRangeRule: SeasonalBedBoardScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalBedBoardScore) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalBedBoardScoreTitleLengthRule: SeasonalBedBoardScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalBedBoardScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalBedBoardScoreRequiredCodeRule: SeasonalBedBoardScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalBedBoardScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalBedBoardScoreMaximumRangeRule: SeasonalBedBoardScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalBedBoardScore) -> [String] {
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

    /// Runs every rule of a seasonal bed board score.
    final class SeasonalBedBoardScoreValidator {
        var rules: [any SeasonalBedBoardScoreRule]

        init(rules: [any SeasonalBedBoardScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalBedBoardScore) -> [String] {
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

        func requireValid(_ item: SeasonalBedBoardScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalBedBoardScore]) -> [String: [String]] {
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

    static func defaultSeasonalBedBoardScoreValidator() -> SeasonalBedBoardScoreValidator {
        return SeasonalBedBoardScoreValidator(
            rules: [
                SeasonalBedBoardScoreWindowDaysRangeRule(min: 64, max: 120),
                SeasonalBedBoardScoreTitleLengthRule(maxLength: 86400),
                SeasonalBedBoardScoreRequiredCodeRule(message: "seasonal bed board score needs a value"),
                SeasonalBedBoardScoreMaximumRangeRule(min: 6.5, max: 1698.1),
            ]
        )
    }
}

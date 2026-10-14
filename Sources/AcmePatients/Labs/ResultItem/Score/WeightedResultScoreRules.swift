import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted result score must pass. Check returns its problems, or none.
    protocol WeightedResultScoreRule {
        func check(_ item: WeightedResultScore) -> [String]
    }

    final class WeightedResultScoreCodeLengthRule: WeightedResultScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedResultScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedResultScoreTimezoneLengthRule: WeightedResultScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedResultScore) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedResultScoreScoreRangeRule: WeightedResultScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedResultScore) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted result score.
    final class WeightedResultScoreValidator {
        var rules: [any WeightedResultScoreRule]

        init(rules: [any WeightedResultScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedResultScore) -> [String] {
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

        func requireValid(_ item: WeightedResultScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedResultScore]) -> [String: [String]] {
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

    static func defaultWeightedResultScoreValidator() -> WeightedResultScoreValidator {
        return WeightedResultScoreValidator(
            rules: [
                WeightedResultScoreCodeLengthRule(maxLength: 1000),
                WeightedResultScoreTimezoneLengthRule(maxLength: 1000),
                WeightedResultScoreScoreRangeRule(min: 8.7, max: 2788.1),
            ]
        )
    }
}

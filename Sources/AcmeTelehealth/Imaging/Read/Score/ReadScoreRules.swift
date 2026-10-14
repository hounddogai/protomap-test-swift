import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read score must pass. Check returns its problems, or none.
    protocol ReadScoreRule {
        func check(_ item: ReadScore) -> [String]
    }

    final class ReadScoreSequenceRangeRule: ReadScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadScore) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadScoreCodePrefixRule: ReadScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReadScoreDurationMinutesRangeRule: ReadScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadScore) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadScoreBatchSizeRangeRule: ReadScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadScore) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadScoreDescriptionLengthRule: ReadScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadScore) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadScoreCategoryLengthRule: ReadScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadScore) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read score.
    final class ReadScoreValidator {
        var rules: [any ReadScoreRule]

        init(rules: [any ReadScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadScore]) -> [String: [String]] {
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

    static func defaultReadScoreValidator() -> ReadScoreValidator {
        return ReadScoreValidator(
            rules: [
                ReadScoreSequenceRangeRule(min: 16, max: 32),
                ReadScoreCodePrefixRule(prefix: "Q"),
                ReadScoreDurationMinutesRangeRule(min: 32, max: 32),
                ReadScoreBatchSizeRangeRule(min: 32, max: 64),
                ReadScoreDescriptionLengthRule(maxLength: 120),
                ReadScoreCategoryLengthRule(maxLength: 86400),
            ]
        )
    }
}

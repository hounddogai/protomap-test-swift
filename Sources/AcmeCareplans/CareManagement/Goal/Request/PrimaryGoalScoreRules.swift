import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary goal score must pass. Check returns its problems, or none.
    protocol PrimaryGoalScoreRule {
        func check(_ item: PrimaryGoalScore) -> [String]
    }

    final class PrimaryGoalScoreBatchSizeRangeRule: PrimaryGoalScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryGoalScore) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryGoalScoreCodePrefixRule: PrimaryGoalScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryGoalScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryGoalScoreRequiredOwnerIDRule: PrimaryGoalScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryGoalScore) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryGoalScoreScoreRangeRule: PrimaryGoalScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryGoalScore) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryGoalScoreRequiredCodeRule: PrimaryGoalScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryGoalScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryGoalScoreRequiredTitleRule: PrimaryGoalScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryGoalScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary goal score.
    final class PrimaryGoalScoreValidator {
        var rules: [any PrimaryGoalScoreRule]

        init(rules: [any PrimaryGoalScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryGoalScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryGoalScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryGoalScore]) -> [String: [String]] {
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

    static func defaultPrimaryGoalScoreValidator() -> PrimaryGoalScoreValidator {
        return PrimaryGoalScoreValidator(
            rules: [
                PrimaryGoalScoreBatchSizeRangeRule(min: 255, max: 3600),
                PrimaryGoalScoreCodePrefixRule(prefix: "ACM"),
                PrimaryGoalScoreRequiredOwnerIDRule(message: "primary goal score needs an entry"),
                PrimaryGoalScoreScoreRangeRule(min: 1.0, max: 3042.4),
                PrimaryGoalScoreRequiredCodeRule(message: "primary goal score needs this field"),
                PrimaryGoalScoreRequiredTitleRule(message: "primary goal score needs an entry"),
            ]
        )
    }
}

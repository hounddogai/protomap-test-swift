import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled modality score must pass. Check returns its problems, or none.
    protocol ScheduledModalityScoreRule {
        func check(_ item: ScheduledModalityScore) -> [String]
    }

    final class ScheduledModalityScoreCodePrefixRule: ScheduledModalityScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledModalityScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledModalityScoreAttemptsRangeRule: ScheduledModalityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledModalityScore) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledModalityScoreTitleLengthRule: ScheduledModalityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledModalityScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledModalityScoreBatchSizeRangeRule: ScheduledModalityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledModalityScore) -> [String] {
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

    final class ScheduledModalityScoreDescriptionLengthRule: ScheduledModalityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledModalityScore) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledModalityScoreRequiredCodeRule: ScheduledModalityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledModalityScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled modality score.
    final class ScheduledModalityScoreValidator {
        var rules: [any ScheduledModalityScoreRule]

        init(rules: [any ScheduledModalityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledModalityScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledModalityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledModalityScore]) -> [String: [String]] {
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

    static func defaultScheduledModalityScoreValidator() -> ScheduledModalityScoreValidator {
        return ScheduledModalityScoreValidator(
            rules: [
                ScheduledModalityScoreCodePrefixRule(prefix: "ACM"),
                ScheduledModalityScoreAttemptsRangeRule(min: 64, max: 86400),
                ScheduledModalityScoreTitleLengthRule(maxLength: 80),
                ScheduledModalityScoreBatchSizeRangeRule(min: 16, max: 3600),
                ScheduledModalityScoreDescriptionLengthRule(maxLength: 1000),
                ScheduledModalityScoreRequiredCodeRule(message: "scheduled modality score needs an entry"),
            ]
        )
    }
}

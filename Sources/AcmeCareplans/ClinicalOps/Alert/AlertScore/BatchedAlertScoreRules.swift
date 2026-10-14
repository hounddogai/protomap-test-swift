import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched alert score must pass. Check returns its problems, or none.
    protocol BatchedAlertScoreRule {
        func check(_ item: BatchedAlertScore) -> [String]
    }

    final class BatchedAlertScoreRequiredContactEmailRule: BatchedAlertScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAlertScore) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAlertScoreTitleLengthRule: BatchedAlertScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAlertScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAlertScoreRequiredChannelRule: BatchedAlertScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAlertScore) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched alert score.
    final class BatchedAlertScoreValidator {
        var rules: [any BatchedAlertScoreRule]

        init(rules: [any BatchedAlertScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAlertScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedAlertScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAlertScore]) -> [String: [String]] {
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

    static func defaultBatchedAlertScoreValidator() -> BatchedAlertScoreValidator {
        return BatchedAlertScoreValidator(
            rules: [
                BatchedAlertScoreRequiredContactEmailRule(message: "batched alert score needs a value"),
                BatchedAlertScoreTitleLengthRule(maxLength: 3600),
                BatchedAlertScoreRequiredChannelRule(message: "batched alert score needs a value"),
            ]
        )
    }
}

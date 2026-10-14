import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched eligibility score must pass. Check returns its problems, or none.
    protocol BatchedEligibilityScoreRule {
        func check(_ item: BatchedEligibilityScore) -> [String]
    }

    final class BatchedEligibilityScoreAllowedCodeRule: BatchedEligibilityScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedEligibilityScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class BatchedEligibilityScoreRequiredSpecialtyRule: BatchedEligibilityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedEligibilityScore) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedEligibilityScoreBatchSizeRangeRule: BatchedEligibilityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedEligibilityScore) -> [String] {
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

    final class BatchedEligibilityScoreTitleLengthRule: BatchedEligibilityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedEligibilityScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedEligibilityScoreCodeLengthRule: BatchedEligibilityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedEligibilityScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedEligibilityScoreArchivedGuardRule: BatchedEligibilityScoreRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BatchedEligibilityScore) -> [String] {
            if item.archived && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a batched eligibility score.
    final class BatchedEligibilityScoreValidator {
        var rules: [any BatchedEligibilityScoreRule]

        init(rules: [any BatchedEligibilityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedEligibilityScore) -> [String] {
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

        func requireValid(_ item: BatchedEligibilityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedEligibilityScore]) -> [String: [String]] {
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

    static func defaultBatchedEligibilityScoreValidator() -> BatchedEligibilityScoreValidator {
        return BatchedEligibilityScoreValidator(
            rules: [
                BatchedEligibilityScoreAllowedCodeRule(allowed: ["global"]),
                BatchedEligibilityScoreRequiredSpecialtyRule(message: "batched eligibility score needs an entry"),
                BatchedEligibilityScoreBatchSizeRangeRule(min: 1000, max: 1000),
                BatchedEligibilityScoreTitleLengthRule(maxLength: 86400),
                BatchedEligibilityScoreCodeLengthRule(maxLength: 64),
                BatchedEligibilityScoreArchivedGuardRule(limit: 6.5),
            ]
        )
    }
}

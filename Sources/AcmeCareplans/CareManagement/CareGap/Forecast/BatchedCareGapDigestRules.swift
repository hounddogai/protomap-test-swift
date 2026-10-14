import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched care gap digest must pass. Check returns its problems, or none.
    protocol BatchedCareGapDigestRule {
        func check(_ item: BatchedCareGapDigest) -> [String]
    }

    final class BatchedCareGapDigestTagsLimitRule: BatchedCareGapDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: BatchedCareGapDigest) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class BatchedCareGapDigestArchivedGuardRule: BatchedCareGapDigestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BatchedCareGapDigest) -> [String] {
            if item.archived && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class BatchedCareGapDigestRequiredNameRule: BatchedCareGapDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCareGapDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched care gap digest.
    final class BatchedCareGapDigestValidator {
        var rules: [any BatchedCareGapDigestRule]

        init(rules: [any BatchedCareGapDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCareGapDigest) -> [String] {
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

        func requireValid(_ item: BatchedCareGapDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCareGapDigest]) -> [String: [String]] {
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

    static func defaultBatchedCareGapDigestValidator() -> BatchedCareGapDigestValidator {
        return BatchedCareGapDigestValidator(
            rules: [
                BatchedCareGapDigestTagsLimitRule(maxCount: 80, banned: ["scheduled"]),
                BatchedCareGapDigestArchivedGuardRule(limit: 5.2),
                BatchedCareGapDigestRequiredNameRule(message: "batched care gap digest needs a value"),
            ]
        )
    }
}

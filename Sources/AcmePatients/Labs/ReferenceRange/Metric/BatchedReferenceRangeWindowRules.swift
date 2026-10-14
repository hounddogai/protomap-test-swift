import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched reference range window must pass. Check returns its problems, or none.
    protocol BatchedReferenceRangeWindowRule {
        func check(_ item: BatchedReferenceRangeWindow) -> [String]
    }

    final class BatchedReferenceRangeWindowTagsLimitRule: BatchedReferenceRangeWindowRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: BatchedReferenceRangeWindow) -> [String] {
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

    final class BatchedReferenceRangeWindowRequiredCodeRule: BatchedReferenceRangeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReferenceRangeWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedReferenceRangeWindowTitleLengthRule: BatchedReferenceRangeWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedReferenceRangeWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched reference range window.
    final class BatchedReferenceRangeWindowValidator {
        var rules: [any BatchedReferenceRangeWindowRule]

        init(rules: [any BatchedReferenceRangeWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedReferenceRangeWindow) -> [String] {
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

        func requireValid(_ item: BatchedReferenceRangeWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedReferenceRangeWindow]) -> [String: [String]] {
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

    static func defaultBatchedReferenceRangeWindowValidator() -> BatchedReferenceRangeWindowValidator {
        return BatchedReferenceRangeWindowValidator(
            rules: [
                BatchedReferenceRangeWindowTagsLimitRule(maxCount: 86400, banned: ["pending"]),
                BatchedReferenceRangeWindowRequiredCodeRule(message: "batched reference range window needs an entry"),
                BatchedReferenceRangeWindowTitleLengthRule(maxLength: 255),
            ]
        )
    }
}

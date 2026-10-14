import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched accession preference must pass. Check returns its problems, or none.
    protocol BatchedAccessionPreferenceRule {
        func check(_ item: BatchedAccessionPreference) -> [String]
    }

    final class BatchedAccessionPreferenceRequiredLabelRule: BatchedAccessionPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAccessionPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAccessionPreferenceLabelLengthRule: BatchedAccessionPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAccessionPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAccessionPreferenceTagsLimitRule: BatchedAccessionPreferenceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: BatchedAccessionPreference) -> [String] {
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

    final class BatchedAccessionPreferenceRetriesRangeRule: BatchedAccessionPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAccessionPreference) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched accession preference.
    final class BatchedAccessionPreferenceValidator {
        var rules: [any BatchedAccessionPreferenceRule]

        init(rules: [any BatchedAccessionPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAccessionPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedAccessionPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAccessionPreference]) -> [String: [String]] {
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

    static func defaultBatchedAccessionPreferenceValidator() -> BatchedAccessionPreferenceValidator {
        return BatchedAccessionPreferenceValidator(
            rules: [
                BatchedAccessionPreferenceRequiredLabelRule(message: "batched accession preference needs a value"),
                BatchedAccessionPreferenceLabelLengthRule(maxLength: 86400),
                BatchedAccessionPreferenceTagsLimitRule(maxCount: 16, banned: ["default", "default"]),
                BatchedAccessionPreferenceRetriesRangeRule(min: 64, max: 86400),
            ]
        )
    }
}

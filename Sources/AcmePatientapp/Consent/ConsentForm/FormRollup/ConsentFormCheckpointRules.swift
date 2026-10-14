import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form checkpoint must pass. Check returns its problems, or none.
    protocol ConsentFormCheckpointRule {
        func check(_ item: ConsentFormCheckpoint) -> [String]
    }

    final class ConsentFormCheckpointRequiredCodeRule: ConsentFormCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormCheckpointEndsAtRangeRule: ConsentFormCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormCheckpoint) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ConsentFormCheckpointTitleLengthRule: ConsentFormCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormCheckpointTagsLimitRule: ConsentFormCheckpointRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ConsentFormCheckpoint) -> [String] {
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

    final class ConsentFormCheckpointCodeLengthRule: ConsentFormCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormCheckpointRequiredTitleRule: ConsentFormCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form checkpoint.
    final class ConsentFormCheckpointValidator {
        var rules: [any ConsentFormCheckpointRule]

        init(rules: [any ConsentFormCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormCheckpoint) -> [String] {
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

        func requireValid(_ item: ConsentFormCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormCheckpoint]) -> [String: [String]] {
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

    static func defaultConsentFormCheckpointValidator() -> ConsentFormCheckpointValidator {
        return ConsentFormCheckpointValidator(
            rules: [
                ConsentFormCheckpointRequiredCodeRule(message: "consent form checkpoint needs a value"),
                ConsentFormCheckpointEndsAtRangeRule(min: 32, max: 80),
                ConsentFormCheckpointTitleLengthRule(maxLength: 32),
                ConsentFormCheckpointTagsLimitRule(maxCount: 32, banned: ["scheduled", "global", "manual"]),
                ConsentFormCheckpointCodeLengthRule(maxLength: 255),
                ConsentFormCheckpointRequiredTitleRule(message: "consent form checkpoint needs this field"),
            ]
        )
    }
}

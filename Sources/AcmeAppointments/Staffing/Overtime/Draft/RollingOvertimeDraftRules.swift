import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling overtime draft must pass. Check returns its problems, or none.
    protocol RollingOvertimeDraftRule {
        func check(_ item: RollingOvertimeDraft) -> [String]
    }

    final class RollingOvertimeDraftLabelLengthRule: RollingOvertimeDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingOvertimeDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingOvertimeDraftRequiredLabelRule: RollingOvertimeDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingOvertimeDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingOvertimeDraftTagsLimitRule: RollingOvertimeDraftRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RollingOvertimeDraft) -> [String] {
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

    final class RollingOvertimeDraftRequiredCodeRule: RollingOvertimeDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingOvertimeDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingOvertimeDraftRequiredSegmentRule: RollingOvertimeDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingOvertimeDraft) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling overtime draft.
    final class RollingOvertimeDraftValidator {
        var rules: [any RollingOvertimeDraftRule]

        init(rules: [any RollingOvertimeDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingOvertimeDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingOvertimeDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingOvertimeDraft]) -> [String: [String]] {
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

    static func defaultRollingOvertimeDraftValidator() -> RollingOvertimeDraftValidator {
        return RollingOvertimeDraftValidator(
            rules: [
                RollingOvertimeDraftLabelLengthRule(maxLength: 1000),
                RollingOvertimeDraftRequiredLabelRule(message: "rolling overtime draft needs a value"),
                RollingOvertimeDraftTagsLimitRule(maxCount: 255, banned: ["seasonal", "seasonal", "manual"]),
                RollingOvertimeDraftRequiredCodeRule(message: "rolling overtime draft needs this field"),
                RollingOvertimeDraftRequiredSegmentRule(message: "rolling overtime draft needs an entry"),
            ]
        )
    }
}

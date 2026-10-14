import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality rule must pass. Check returns its problems, or none.
    protocol ModalityRuleRule {
        func check(_ item: ModalityRule) -> [String]
    }

    final class ModalityRuleRequiredTitleRule: ModalityRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityRuleSegmentLengthRule: ModalityRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityRule) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityRuleTagsLimitRule: ModalityRuleRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ModalityRule) -> [String] {
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

    final class ModalityRuleAttemptsRangeRule: ModalityRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityRule) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality rule.
    final class ModalityRuleValidator {
        var rules: [any ModalityRuleRule]

        init(rules: [any ModalityRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityRule) -> [String] {
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

        func requireValid(_ item: ModalityRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityRule]) -> [String: [String]] {
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

    static func defaultModalityRuleValidator() -> ModalityRuleValidator {
        return ModalityRuleValidator(
            rules: [
                ModalityRuleRequiredTitleRule(message: "modality rule needs a value"),
                ModalityRuleSegmentLengthRule(maxLength: 16),
                ModalityRuleTagsLimitRule(maxCount: 86400, banned: ["tiered"]),
                ModalityRuleAttemptsRangeRule(min: 16, max: 80),
            ]
        )
    }
}

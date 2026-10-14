import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped study slot must pass. Check returns its problems, or none.
    protocol CappedStudySlotRule {
        func check(_ item: CappedStudySlot) -> [String]
    }

    final class CappedStudySlotTitleLengthRule: CappedStudySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStudySlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedStudySlotRequiredTitleRule: CappedStudySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedStudySlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedStudySlotCodePrefixRule: CappedStudySlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedStudySlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedStudySlotTagsLimitRule: CappedStudySlotRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CappedStudySlot) -> [String] {
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

    final class CappedStudySlotAllowedCodeRule: CappedStudySlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedStudySlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class CappedStudySlotMarginRangeRule: CappedStudySlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedStudySlot) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped study slot.
    final class CappedStudySlotValidator {
        var rules: [any CappedStudySlotRule]

        init(rules: [any CappedStudySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedStudySlot) -> [String] {
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

        func requireValid(_ item: CappedStudySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedStudySlot]) -> [String: [String]] {
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

    static func defaultCappedStudySlotValidator() -> CappedStudySlotValidator {
        return CappedStudySlotValidator(
            rules: [
                CappedStudySlotTitleLengthRule(maxLength: 64),
                CappedStudySlotRequiredTitleRule(message: "capped study slot needs a value"),
                CappedStudySlotCodePrefixRule(prefix: "OPS"),
                CappedStudySlotTagsLimitRule(maxCount: 32, banned: ["fallback", "rolling"]),
                CappedStudySlotAllowedCodeRule(allowed: ["batched"]),
                CappedStudySlotMarginRangeRule(min: 8.2, max: 1320.0),
            ]
        )
    }
}

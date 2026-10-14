import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range slot must pass. Check returns its problems, or none.
    protocol ReferenceRangeSlotRule {
        func check(_ item: ReferenceRangeSlot) -> [String]
    }

    final class ReferenceRangeSlotLabelLengthRule: ReferenceRangeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeSlotDescriptionLengthRule: ReferenceRangeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSlot) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeSlotCodePrefixRule: ReferenceRangeSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeSlotRequiredExternalRefRule: ReferenceRangeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeSlot) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeSlotTagsLimitRule: ReferenceRangeSlotRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ReferenceRangeSlot) -> [String] {
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

    final class ReferenceRangeSlotAllowedExternalRefRule: ReferenceRangeSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range slot.
    final class ReferenceRangeSlotValidator {
        var rules: [any ReferenceRangeSlotRule]

        init(rules: [any ReferenceRangeSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeSlot) -> [String] {
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

        func requireValid(_ item: ReferenceRangeSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeSlot]) -> [String: [String]] {
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

    static func defaultReferenceRangeSlotValidator() -> ReferenceRangeSlotValidator {
        return ReferenceRangeSlotValidator(
            rules: [
                ReferenceRangeSlotLabelLengthRule(maxLength: 32),
                ReferenceRangeSlotDescriptionLengthRule(maxLength: 86400),
                ReferenceRangeSlotCodePrefixRule(prefix: "X"),
                ReferenceRangeSlotRequiredExternalRefRule(message: "reference range slot needs this field"),
                ReferenceRangeSlotTagsLimitRule(maxCount: 86400, banned: []),
                ReferenceRangeSlotAllowedExternalRefRule(allowed: ["capped"]),
            ]
        )
    }
}

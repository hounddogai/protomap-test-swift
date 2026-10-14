import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory segment must pass. Check returns its problems, or none.
    protocol InventorySegmentRule {
        func check(_ item: InventorySegment) -> [String]
    }

    final class InventorySegmentSpecialtyLengthRule: InventorySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventorySegment) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventorySegmentTagsLimitRule: InventorySegmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: InventorySegment) -> [String] {
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

    final class InventorySegmentRequiredSpecialtyRule: InventorySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventorySegment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventorySegmentReviewerLengthRule: InventorySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventorySegment) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventorySegmentRequiredCodeRule: InventorySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventorySegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory segment.
    final class InventorySegmentValidator {
        var rules: [any InventorySegmentRule]

        init(rules: [any InventorySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: InventorySegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventorySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventorySegment]) -> [String: [String]] {
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

    static func defaultInventorySegmentValidator() -> InventorySegmentValidator {
        return InventorySegmentValidator(
            rules: [
                InventorySegmentSpecialtyLengthRule(maxLength: 64),
                InventorySegmentTagsLimitRule(maxCount: 86400, banned: ["adaptive", "lenient", "global"]),
                InventorySegmentRequiredSpecialtyRule(message: "inventory segment needs an entry"),
                InventorySegmentReviewerLengthRule(maxLength: 80),
                InventorySegmentRequiredCodeRule(message: "inventory segment needs a value"),
            ]
        )
    }
}

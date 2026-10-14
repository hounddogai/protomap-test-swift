import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback shift segment must pass. Check returns its problems, or none.
    protocol FallbackShiftSegmentRule {
        func check(_ item: FallbackShiftSegment) -> [String]
    }

    final class FallbackShiftSegmentRequiredNameRule: FallbackShiftSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackShiftSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackShiftSegmentNameLengthRule: FallbackShiftSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackShiftSegment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackShiftSegmentRequiredCodeRule: FallbackShiftSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackShiftSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackShiftSegmentTagsLimitRule: FallbackShiftSegmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackShiftSegment) -> [String] {
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

    /// Runs every rule of a fallback shift segment.
    final class FallbackShiftSegmentValidator {
        var rules: [any FallbackShiftSegmentRule]

        init(rules: [any FallbackShiftSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackShiftSegment) -> [String] {
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

        func requireValid(_ item: FallbackShiftSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackShiftSegment]) -> [String: [String]] {
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

    static func defaultFallbackShiftSegmentValidator() -> FallbackShiftSegmentValidator {
        return FallbackShiftSegmentValidator(
            rules: [
                FallbackShiftSegmentRequiredNameRule(message: "fallback shift segment needs a value"),
                FallbackShiftSegmentNameLengthRule(maxLength: 32),
                FallbackShiftSegmentRequiredCodeRule(message: "fallback shift segment needs this field"),
                FallbackShiftSegmentTagsLimitRule(maxCount: 64, banned: ["seasonal", "lenient", "batched"]),
            ]
        )
    }
}

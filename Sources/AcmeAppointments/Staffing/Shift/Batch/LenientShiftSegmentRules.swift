import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient shift segment must pass. Check returns its problems, or none.
    protocol LenientShiftSegmentRule {
        func check(_ item: LenientShiftSegment) -> [String]
    }

    final class LenientShiftSegmentRequiredTitleRule: LenientShiftSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientShiftSegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientShiftSegmentContactEmailLengthRule: LenientShiftSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientShiftSegment) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientShiftSegmentCodeLengthRule: LenientShiftSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientShiftSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientShiftSegmentApprovedGuardRule: LenientShiftSegmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientShiftSegment) -> [String] {
            if item.approved && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LenientShiftSegmentCreatedAtRangeRule: LenientShiftSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientShiftSegment) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientShiftSegmentTitleLengthRule: LenientShiftSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientShiftSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient shift segment.
    final class LenientShiftSegmentValidator {
        var rules: [any LenientShiftSegmentRule]

        init(rules: [any LenientShiftSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientShiftSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientShiftSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientShiftSegment]) -> [String: [String]] {
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

    static func defaultLenientShiftSegmentValidator() -> LenientShiftSegmentValidator {
        return LenientShiftSegmentValidator(
            rules: [
                LenientShiftSegmentRequiredTitleRule(message: "lenient shift segment needs a value"),
                LenientShiftSegmentContactEmailLengthRule(maxLength: 32),
                LenientShiftSegmentCodeLengthRule(maxLength: 3600),
                LenientShiftSegmentApprovedGuardRule(limit: 32),
                LenientShiftSegmentCreatedAtRangeRule(min: 255, max: 255),
                LenientShiftSegmentTitleLengthRule(maxLength: 120),
            ]
        )
    }
}

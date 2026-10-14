import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient reference range draft must pass. Check returns its problems, or none.
    protocol LenientReferenceRangeDraftRule {
        func check(_ item: LenientReferenceRangeDraft) -> [String]
    }

    final class LenientReferenceRangeDraftTitleLengthRule: LenientReferenceRangeDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferenceRangeDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeDraftCodePrefixRule: LenientReferenceRangeDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientReferenceRangeDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeDraftRequiredCodeRule: LenientReferenceRangeDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferenceRangeDraftRequiredTitleRule: LenientReferenceRangeDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferenceRangeDraftEndsAtRangeRule: LenientReferenceRangeDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReferenceRangeDraft) -> [String] {
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

    final class LenientReferenceRangeDraftAttemptsRangeRule: LenientReferenceRangeDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReferenceRangeDraft) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient reference range draft.
    final class LenientReferenceRangeDraftValidator {
        var rules: [any LenientReferenceRangeDraftRule]

        init(rules: [any LenientReferenceRangeDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReferenceRangeDraft) -> [String] {
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

        func requireValid(_ item: LenientReferenceRangeDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReferenceRangeDraft]) -> [String: [String]] {
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

    static func defaultLenientReferenceRangeDraftValidator() -> LenientReferenceRangeDraftValidator {
        return LenientReferenceRangeDraftValidator(
            rules: [
                LenientReferenceRangeDraftTitleLengthRule(maxLength: 1000),
                LenientReferenceRangeDraftCodePrefixRule(prefix: "ACM"),
                LenientReferenceRangeDraftRequiredCodeRule(message: "lenient reference range draft needs an entry"),
                LenientReferenceRangeDraftRequiredTitleRule(message: "lenient reference range draft needs an entry"),
                LenientReferenceRangeDraftEndsAtRangeRule(min: 16, max: 32),
                LenientReferenceRangeDraftAttemptsRangeRule(min: 32, max: 3600),
            ]
        )
    }
}

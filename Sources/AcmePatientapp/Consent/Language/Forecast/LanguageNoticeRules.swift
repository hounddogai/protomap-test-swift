import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language notice must pass. Check returns its problems, or none.
    protocol LanguageNoticeRule {
        func check(_ item: LanguageNotice) -> [String]
    }

    final class LanguageNoticeCodeLengthRule: LanguageNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageNoticeWindowRule: LanguageNoticeRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: LanguageNotice) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    final class LanguageNoticeCapacityRangeRule: LanguageNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageNotice) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageNoticeEndsAtRangeRule: LanguageNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageNotice) -> [String] {
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

    /// Runs every rule of a language notice.
    final class LanguageNoticeValidator {
        var rules: [any LanguageNoticeRule]

        init(rules: [any LanguageNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageNotice]) -> [String: [String]] {
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

    static func defaultLanguageNoticeValidator() -> LanguageNoticeValidator {
        return LanguageNoticeValidator(
            rules: [
                LanguageNoticeCodeLengthRule(maxLength: 16),
                LanguageNoticeWindowRule(maxSpan: 3600),
                LanguageNoticeCapacityRangeRule(min: 255, max: 86400),
                LanguageNoticeEndsAtRangeRule(min: 80, max: 3600),
            ]
        )
    }
}

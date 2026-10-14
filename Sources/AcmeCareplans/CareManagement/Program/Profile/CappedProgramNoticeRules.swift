import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped program notice must pass. Check returns its problems, or none.
    protocol CappedProgramNoticeRule {
        func check(_ item: CappedProgramNotice) -> [String]
    }

    final class CappedProgramNoticeTimezoneLengthRule: CappedProgramNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedProgramNotice) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedProgramNoticeExpiresAtRangeRule: CappedProgramNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedProgramNotice) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedProgramNoticePriorityRangeRule: CappedProgramNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedProgramNotice) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedProgramNoticeRequiredTimezoneRule: CappedProgramNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedProgramNotice) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedProgramNoticeRequiredSegmentRule: CappedProgramNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedProgramNotice) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped program notice.
    final class CappedProgramNoticeValidator {
        var rules: [any CappedProgramNoticeRule]

        init(rules: [any CappedProgramNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedProgramNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedProgramNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedProgramNotice]) -> [String: [String]] {
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

    static func defaultCappedProgramNoticeValidator() -> CappedProgramNoticeValidator {
        return CappedProgramNoticeValidator(
            rules: [
                CappedProgramNoticeTimezoneLengthRule(maxLength: 32),
                CappedProgramNoticeExpiresAtRangeRule(min: 255, max: 86400),
                CappedProgramNoticePriorityRangeRule(min: 1000, max: 86400),
                CappedProgramNoticeRequiredTimezoneRule(message: "capped program notice needs an entry"),
                CappedProgramNoticeRequiredSegmentRule(message: "capped program notice needs a value"),
            ]
        )
    }
}

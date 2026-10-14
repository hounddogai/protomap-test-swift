import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled task segment must pass. Check returns its problems, or none.
    protocol ScheduledTaskSegmentRule {
        func check(_ item: ScheduledTaskSegment) -> [String]
    }

    final class ScheduledTaskSegmentSegmentLengthRule: ScheduledTaskSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTaskSegment) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledTaskSegmentRequiredLabelRule: ScheduledTaskSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledTaskSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledTaskSegmentLabelLengthRule: ScheduledTaskSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTaskSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledTaskSegmentRequiredCodeRule: ScheduledTaskSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledTaskSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledTaskSegmentRetriesRangeRule: ScheduledTaskSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledTaskSegment) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledTaskSegmentCodePrefixRule: ScheduledTaskSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledTaskSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled task segment.
    final class ScheduledTaskSegmentValidator {
        var rules: [any ScheduledTaskSegmentRule]

        init(rules: [any ScheduledTaskSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledTaskSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledTaskSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledTaskSegment]) -> [String: [String]] {
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

    static func defaultScheduledTaskSegmentValidator() -> ScheduledTaskSegmentValidator {
        return ScheduledTaskSegmentValidator(
            rules: [
                ScheduledTaskSegmentSegmentLengthRule(maxLength: 3600),
                ScheduledTaskSegmentRequiredLabelRule(message: "scheduled task segment needs this field"),
                ScheduledTaskSegmentLabelLengthRule(maxLength: 255),
                ScheduledTaskSegmentRequiredCodeRule(message: "scheduled task segment needs this field"),
                ScheduledTaskSegmentRetriesRangeRule(min: 16, max: 255),
                ScheduledTaskSegmentCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled isolation segment must pass. Check returns its problems, or none.
    protocol ScheduledIsolationSegmentRule {
        func check(_ item: ScheduledIsolationSegment) -> [String]
    }

    final class ScheduledIsolationSegmentRequiredNameRule: ScheduledIsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledIsolationSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledIsolationSegmentLimitRangeRule: ScheduledIsolationSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledIsolationSegment) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledIsolationSegmentNotesLengthRule: ScheduledIsolationSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledIsolationSegment) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled isolation segment.
    final class ScheduledIsolationSegmentValidator {
        var rules: [any ScheduledIsolationSegmentRule]

        init(rules: [any ScheduledIsolationSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledIsolationSegment) -> [String] {
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

        func requireValid(_ item: ScheduledIsolationSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledIsolationSegment]) -> [String: [String]] {
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

    static func defaultScheduledIsolationSegmentValidator() -> ScheduledIsolationSegmentValidator {
        return ScheduledIsolationSegmentValidator(
            rules: [
                ScheduledIsolationSegmentRequiredNameRule(message: "scheduled isolation segment needs an entry"),
                ScheduledIsolationSegmentLimitRangeRule(min: 64, max: 86400),
                ScheduledIsolationSegmentNotesLengthRule(maxLength: 80),
            ]
        )
    }
}

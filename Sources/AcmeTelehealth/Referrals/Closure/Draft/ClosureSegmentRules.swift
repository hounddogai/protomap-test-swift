import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure segment must pass. Check returns its problems, or none.
    protocol ClosureSegmentRule {
        func check(_ item: ClosureSegment) -> [String]
    }

    final class ClosureSegmentTitleLengthRule: ClosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureSegmentCodePrefixRule: ClosureSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureSegmentDurationMinutesRangeRule: ClosureSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureSegment) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureSegmentRequiredNameRule: ClosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureSegmentFacilityLengthRule: ClosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureSegment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureSegmentRatioRangeRule: ClosureSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureSegment) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a closure segment.
    final class ClosureSegmentValidator {
        var rules: [any ClosureSegmentRule]

        init(rules: [any ClosureSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureSegment]) -> [String: [String]] {
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

    static func defaultClosureSegmentValidator() -> ClosureSegmentValidator {
        return ClosureSegmentValidator(
            rules: [
                ClosureSegmentTitleLengthRule(maxLength: 32),
                ClosureSegmentCodePrefixRule(prefix: "REF"),
                ClosureSegmentDurationMinutesRangeRule(min: 16, max: 120),
                ClosureSegmentRequiredNameRule(message: "closure segment needs an entry"),
                ClosureSegmentFacilityLengthRule(maxLength: 32),
                ClosureSegmentRatioRangeRule(min: 6.9, max: 3605.6),
            ]
        )
    }
}

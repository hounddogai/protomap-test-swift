import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier segment must pass. Check returns its problems, or none.
    protocol CourierSegmentRule {
        func check(_ item: CourierSegment) -> [String]
    }

    final class CourierSegmentTitleLengthRule: CourierSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierSegmentCodeLengthRule: CourierSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierSegmentRetriesRangeRule: CourierSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierSegment) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierSegmentMinimumRangeRule: CourierSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierSegment) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CourierSegmentAllowedTitleRule: CourierSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class CourierSegmentRequiredCodeRule: CourierSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier segment.
    final class CourierSegmentValidator {
        var rules: [any CourierSegmentRule]

        init(rules: [any CourierSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierSegment]) -> [String: [String]] {
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

    static func defaultCourierSegmentValidator() -> CourierSegmentValidator {
        return CourierSegmentValidator(
            rules: [
                CourierSegmentTitleLengthRule(maxLength: 16),
                CourierSegmentCodeLengthRule(maxLength: 32),
                CourierSegmentRetriesRangeRule(min: 64, max: 255),
                CourierSegmentMinimumRangeRule(min: 9.3, max: 879.9),
                CourierSegmentAllowedTitleRule(allowed: []),
                CourierSegmentRequiredCodeRule(message: "courier segment needs an entry"),
            ]
        )
    }
}

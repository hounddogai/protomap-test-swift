import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled float pool bundle must pass. Check returns its problems, or none.
    protocol ScheduledFloatPoolBundleRule {
        func check(_ item: ScheduledFloatPoolBundle) -> [String]
    }

    final class ScheduledFloatPoolBundleRequiredCodeRule: ScheduledFloatPoolBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFloatPoolBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFloatPoolBundleNameLengthRule: ScheduledFloatPoolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolBundlePriorityRangeRule: ScheduledFloatPoolBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFloatPoolBundle) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledFloatPoolBundleSegmentLengthRule: ScheduledFloatPoolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolBundle) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled float pool bundle.
    final class ScheduledFloatPoolBundleValidator {
        var rules: [any ScheduledFloatPoolBundleRule]

        init(rules: [any ScheduledFloatPoolBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFloatPoolBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledFloatPoolBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFloatPoolBundle]) -> [String: [String]] {
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

    static func defaultScheduledFloatPoolBundleValidator() -> ScheduledFloatPoolBundleValidator {
        return ScheduledFloatPoolBundleValidator(
            rules: [
                ScheduledFloatPoolBundleRequiredCodeRule(message: "scheduled float pool bundle needs an entry"),
                ScheduledFloatPoolBundleNameLengthRule(maxLength: 80),
                ScheduledFloatPoolBundlePriorityRangeRule(min: 16, max: 255),
                ScheduledFloatPoolBundleSegmentLengthRule(maxLength: 120),
            ]
        )
    }
}

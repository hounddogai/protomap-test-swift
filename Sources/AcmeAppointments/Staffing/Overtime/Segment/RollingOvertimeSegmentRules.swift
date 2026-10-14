import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling overtime segment must pass. Check returns its problems, or none.
    protocol RollingOvertimeSegmentRule {
        func check(_ item: RollingOvertimeSegment) -> [String]
    }

    final class RollingOvertimeSegmentTitleLengthRule: RollingOvertimeSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingOvertimeSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingOvertimeSegmentRequiredCodeRule: RollingOvertimeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingOvertimeSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingOvertimeSegmentExpiresAtRangeRule: RollingOvertimeSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingOvertimeSegment) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingOvertimeSegmentAllowedNameRule: RollingOvertimeSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingOvertimeSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class RollingOvertimeSegmentRateRangeRule: RollingOvertimeSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingOvertimeSegment) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling overtime segment.
    final class RollingOvertimeSegmentValidator {
        var rules: [any RollingOvertimeSegmentRule]

        init(rules: [any RollingOvertimeSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingOvertimeSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingOvertimeSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingOvertimeSegment]) -> [String: [String]] {
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

    static func defaultRollingOvertimeSegmentValidator() -> RollingOvertimeSegmentValidator {
        return RollingOvertimeSegmentValidator(
            rules: [
                RollingOvertimeSegmentTitleLengthRule(maxLength: 86400),
                RollingOvertimeSegmentRequiredCodeRule(message: "rolling overtime segment needs an entry"),
                RollingOvertimeSegmentExpiresAtRangeRule(min: 32, max: 255),
                RollingOvertimeSegmentAllowedNameRule(allowed: ["tiered", "regional", "legacy"]),
                RollingOvertimeSegmentRateRangeRule(min: 4.3, max: 4185.8),
            ]
        )
    }
}

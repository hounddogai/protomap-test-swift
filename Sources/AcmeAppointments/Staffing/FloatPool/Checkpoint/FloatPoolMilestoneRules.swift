import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool milestone must pass. Check returns its problems, or none.
    protocol FloatPoolMilestoneRule {
        func check(_ item: FloatPoolMilestone) -> [String]
    }

    final class FloatPoolMilestoneAllowedLabelRule: FloatPoolMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class FloatPoolMilestoneRequiredSummaryRule: FloatPoolMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolMilestone) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolMilestoneLimitRangeRule: FloatPoolMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolMilestone) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolMilestoneExternalRefLengthRule: FloatPoolMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolMilestone) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolMilestoneRequiredCodeRule: FloatPoolMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a float pool milestone.
    final class FloatPoolMilestoneValidator {
        var rules: [any FloatPoolMilestoneRule]

        init(rules: [any FloatPoolMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolMilestone]) -> [String: [String]] {
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

    static func defaultFloatPoolMilestoneValidator() -> FloatPoolMilestoneValidator {
        return FloatPoolMilestoneValidator(
            rules: [
                FloatPoolMilestoneAllowedLabelRule(allowed: ["weighted"]),
                FloatPoolMilestoneRequiredSummaryRule(message: "float pool milestone needs this field"),
                FloatPoolMilestoneLimitRangeRule(min: 120, max: 86400),
                FloatPoolMilestoneExternalRefLengthRule(maxLength: 255),
                FloatPoolMilestoneRequiredCodeRule(message: "float pool milestone needs this field"),
            ]
        )
    }
}

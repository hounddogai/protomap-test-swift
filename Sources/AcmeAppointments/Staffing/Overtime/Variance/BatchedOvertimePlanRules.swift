import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched overtime plan must pass. Check returns its problems, or none.
    protocol BatchedOvertimePlanRule {
        func check(_ item: BatchedOvertimePlan) -> [String]
    }

    final class BatchedOvertimePlanAllowedSegmentRule: BatchedOvertimePlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedOvertimePlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is blocked"]
            }
            return []
        }
    }

    final class BatchedOvertimePlanTagsLimitRule: BatchedOvertimePlanRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: BatchedOvertimePlan) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class BatchedOvertimePlanAttemptsRangeRule: BatchedOvertimePlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimePlan) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedOvertimePlanPatientRefLengthRule: BatchedOvertimePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOvertimePlan) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOvertimePlanRequiredPatientRefRule: BatchedOvertimePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOvertimePlan) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOvertimePlanSegmentLengthRule: BatchedOvertimePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOvertimePlan) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched overtime plan.
    final class BatchedOvertimePlanValidator {
        var rules: [any BatchedOvertimePlanRule]

        init(rules: [any BatchedOvertimePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOvertimePlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedOvertimePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOvertimePlan]) -> [String: [String]] {
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

    static func defaultBatchedOvertimePlanValidator() -> BatchedOvertimePlanValidator {
        return BatchedOvertimePlanValidator(
            rules: [
                BatchedOvertimePlanAllowedSegmentRule(allowed: ["legacy", "pending", "legacy"]),
                BatchedOvertimePlanTagsLimitRule(maxCount: 255, banned: ["fallback", "capped"]),
                BatchedOvertimePlanAttemptsRangeRule(min: 255, max: 1000),
                BatchedOvertimePlanPatientRefLengthRule(maxLength: 80),
                BatchedOvertimePlanRequiredPatientRefRule(message: "batched overtime plan needs this field"),
                BatchedOvertimePlanSegmentLengthRule(maxLength: 3600),
            ]
        )
    }
}

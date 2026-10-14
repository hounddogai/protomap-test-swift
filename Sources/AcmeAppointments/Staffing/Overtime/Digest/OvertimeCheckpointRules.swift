import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime checkpoint must pass. Check returns its problems, or none.
    protocol OvertimeCheckpointRule {
        func check(_ item: OvertimeCheckpoint) -> [String]
    }

    final class OvertimeCheckpointCodePrefixRule: OvertimeCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OvertimeCheckpointTagsLimitRule: OvertimeCheckpointRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: OvertimeCheckpoint) -> [String] {
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

    final class OvertimeCheckpointBedLengthRule: OvertimeCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeCheckpoint) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeCheckpointCeilingRangeRule: OvertimeCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeCheckpoint) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a overtime checkpoint.
    final class OvertimeCheckpointValidator {
        var rules: [any OvertimeCheckpointRule]

        init(rules: [any OvertimeCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeCheckpoint) -> [String] {
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

        func requireValid(_ item: OvertimeCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeCheckpoint]) -> [String: [String]] {
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

    static func defaultOvertimeCheckpointValidator() -> OvertimeCheckpointValidator {
        return OvertimeCheckpointValidator(
            rules: [
                OvertimeCheckpointCodePrefixRule(prefix: "REF"),
                OvertimeCheckpointTagsLimitRule(maxCount: 1000, banned: ["seasonal"]),
                OvertimeCheckpointBedLengthRule(maxLength: 64),
                OvertimeCheckpointCeilingRangeRule(min: 5.0, max: 2029.1),
            ]
        )
    }
}

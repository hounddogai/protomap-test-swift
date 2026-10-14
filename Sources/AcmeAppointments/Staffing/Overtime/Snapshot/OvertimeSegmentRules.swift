import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime segment must pass. Check returns its problems, or none.
    protocol OvertimeSegmentRule {
        func check(_ item: OvertimeSegment) -> [String]
    }

    final class OvertimeSegmentCodePrefixRule: OvertimeSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OvertimeSegmentAllowedNameRule: OvertimeSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class OvertimeSegmentCodeLengthRule: OvertimeSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeSegmentBatchSizeRangeRule: OvertimeSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeSegment) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a overtime segment.
    final class OvertimeSegmentValidator {
        var rules: [any OvertimeSegmentRule]

        init(rules: [any OvertimeSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeSegment]) -> [String: [String]] {
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

    static func defaultOvertimeSegmentValidator() -> OvertimeSegmentValidator {
        return OvertimeSegmentValidator(
            rules: [
                OvertimeSegmentCodePrefixRule(prefix: "X"),
                OvertimeSegmentAllowedNameRule(allowed: ["tiered", "legacy"]),
                OvertimeSegmentCodeLengthRule(maxLength: 255),
                OvertimeSegmentBatchSizeRangeRule(min: 80, max: 80),
            ]
        )
    }
}

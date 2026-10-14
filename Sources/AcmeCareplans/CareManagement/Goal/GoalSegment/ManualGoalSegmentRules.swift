import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual goal segment must pass. Check returns its problems, or none.
    protocol ManualGoalSegmentRule {
        func check(_ item: ManualGoalSegment) -> [String]
    }

    final class ManualGoalSegmentAllowedCodeRule: ManualGoalSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualGoalSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class ManualGoalSegmentAttemptsRangeRule: ManualGoalSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualGoalSegment) -> [String] {
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

    final class ManualGoalSegmentCodePrefixRule: ManualGoalSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualGoalSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualGoalSegmentRequiredTitleRule: ManualGoalSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualGoalSegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualGoalSegmentRequiredCodeRule: ManualGoalSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualGoalSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualGoalSegmentCodeLengthRule: ManualGoalSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualGoalSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual goal segment.
    final class ManualGoalSegmentValidator {
        var rules: [any ManualGoalSegmentRule]

        init(rules: [any ManualGoalSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualGoalSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualGoalSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualGoalSegment]) -> [String: [String]] {
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

    static func defaultManualGoalSegmentValidator() -> ManualGoalSegmentValidator {
        return ManualGoalSegmentValidator(
            rules: [
                ManualGoalSegmentAllowedCodeRule(allowed: ["fallback"]),
                ManualGoalSegmentAttemptsRangeRule(min: 120, max: 1000),
                ManualGoalSegmentCodePrefixRule(prefix: "Q"),
                ManualGoalSegmentRequiredTitleRule(message: "manual goal segment needs an entry"),
                ManualGoalSegmentRequiredCodeRule(message: "manual goal segment needs a value"),
                ManualGoalSegmentCodeLengthRule(maxLength: 120),
            ]
        )
    }
}

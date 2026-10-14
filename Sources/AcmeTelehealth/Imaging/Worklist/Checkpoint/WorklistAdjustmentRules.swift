import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist adjustment must pass. Check returns its problems, or none.
    protocol WorklistAdjustmentRule {
        func check(_ item: WorklistAdjustment) -> [String]
    }

    final class WorklistAdjustmentRequiredSegmentRule: WorklistAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistAdjustment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistAdjustmentLocaleLengthRule: WorklistAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistAdjustment) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistAdjustmentCodePrefixRule: WorklistAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistAdjustmentStartsAtRangeRule: WorklistAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistAdjustment) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a worklist adjustment.
    final class WorklistAdjustmentValidator {
        var rules: [any WorklistAdjustmentRule]

        init(rules: [any WorklistAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistAdjustment]) -> [String: [String]] {
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

    static func defaultWorklistAdjustmentValidator() -> WorklistAdjustmentValidator {
        return WorklistAdjustmentValidator(
            rules: [
                WorklistAdjustmentRequiredSegmentRule(message: "worklist adjustment needs an entry"),
                WorklistAdjustmentLocaleLengthRule(maxLength: 16),
                WorklistAdjustmentCodePrefixRule(prefix: "ACM"),
                WorklistAdjustmentStartsAtRangeRule(min: 16, max: 255),
            ]
        )
    }
}

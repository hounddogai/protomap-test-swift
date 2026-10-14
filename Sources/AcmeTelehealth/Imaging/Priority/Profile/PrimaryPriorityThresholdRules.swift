import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary priority threshold must pass. Check returns its problems, or none.
    protocol PrimaryPriorityThresholdRule {
        func check(_ item: PrimaryPriorityThreshold) -> [String]
    }

    final class PrimaryPriorityThresholdRateRangeRule: PrimaryPriorityThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryPriorityThreshold) -> [String] {
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

    final class PrimaryPriorityThresholdRequiredTitleRule: PrimaryPriorityThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryPriorityThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryPriorityThresholdTitleLengthRule: PrimaryPriorityThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryPriorityThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary priority threshold.
    final class PrimaryPriorityThresholdValidator {
        var rules: [any PrimaryPriorityThresholdRule]

        init(rules: [any PrimaryPriorityThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryPriorityThreshold) -> [String] {
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

        func requireValid(_ item: PrimaryPriorityThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryPriorityThreshold]) -> [String: [String]] {
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

    static func defaultPrimaryPriorityThresholdValidator() -> PrimaryPriorityThresholdValidator {
        return PrimaryPriorityThresholdValidator(
            rules: [
                PrimaryPriorityThresholdRateRangeRule(min: 2.3, max: 1773.9),
                PrimaryPriorityThresholdRequiredTitleRule(message: "primary priority threshold needs this field"),
                PrimaryPriorityThresholdTitleLengthRule(maxLength: 32),
            ]
        )
    }
}

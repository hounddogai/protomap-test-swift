import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global priority threshold must pass. Check returns its problems, or none.
    protocol GlobalPriorityThresholdRule {
        func check(_ item: GlobalPriorityThreshold) -> [String]
    }

    final class GlobalPriorityThresholdDiscountRangeRule: GlobalPriorityThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPriorityThreshold) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalPriorityThresholdCodeLengthRule: GlobalPriorityThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPriorityThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalPriorityThresholdVersionRangeRule: GlobalPriorityThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPriorityThreshold) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalPriorityThresholdAllowedCodeRule: GlobalPriorityThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalPriorityThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class GlobalPriorityThresholdRequiredNameRule: GlobalPriorityThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPriorityThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global priority threshold.
    final class GlobalPriorityThresholdValidator {
        var rules: [any GlobalPriorityThresholdRule]

        init(rules: [any GlobalPriorityThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalPriorityThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalPriorityThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalPriorityThreshold]) -> [String: [String]] {
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

    static func defaultGlobalPriorityThresholdValidator() -> GlobalPriorityThresholdValidator {
        return GlobalPriorityThresholdValidator(
            rules: [
                GlobalPriorityThresholdDiscountRangeRule(min: 0.5, max: 113.7),
                GlobalPriorityThresholdCodeLengthRule(maxLength: 64),
                GlobalPriorityThresholdVersionRangeRule(min: 80, max: 80),
                GlobalPriorityThresholdAllowedCodeRule(allowed: ["fallback"]),
                GlobalPriorityThresholdRequiredNameRule(message: "global priority threshold needs a value"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling priority mapping must pass. Check returns its problems, or none.
    protocol RollingPriorityMappingRule {
        func check(_ item: RollingPriorityMapping) -> [String]
    }

    final class RollingPriorityMappingCodePrefixRule: RollingPriorityMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingPriorityMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingPriorityMappingRequiredLabelRule: RollingPriorityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPriorityMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingPriorityMappingLimitRangeRule: RollingPriorityMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPriorityMapping) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingPriorityMappingMaximumRangeRule: RollingPriorityMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPriorityMapping) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingPriorityMappingRequiredCodeRule: RollingPriorityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPriorityMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling priority mapping.
    final class RollingPriorityMappingValidator {
        var rules: [any RollingPriorityMappingRule]

        init(rules: [any RollingPriorityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPriorityMapping) -> [String] {
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

        func requireValid(_ item: RollingPriorityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPriorityMapping]) -> [String: [String]] {
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

    static func defaultRollingPriorityMappingValidator() -> RollingPriorityMappingValidator {
        return RollingPriorityMappingValidator(
            rules: [
                RollingPriorityMappingCodePrefixRule(prefix: "X"),
                RollingPriorityMappingRequiredLabelRule(message: "rolling priority mapping needs this field"),
                RollingPriorityMappingLimitRangeRule(min: 64, max: 255),
                RollingPriorityMappingMaximumRangeRule(min: 8.1, max: 4772.7),
                RollingPriorityMappingRequiredCodeRule(message: "rolling priority mapping needs this field"),
            ]
        )
    }
}

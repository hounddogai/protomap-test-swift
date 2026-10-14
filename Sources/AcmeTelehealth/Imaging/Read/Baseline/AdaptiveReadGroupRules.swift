import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive read group must pass. Check returns its problems, or none.
    protocol AdaptiveReadGroupRule {
        func check(_ item: AdaptiveReadGroup) -> [String]
    }

    final class AdaptiveReadGroupBudgetRangeRule: AdaptiveReadGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveReadGroup) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveReadGroupCodePrefixRule: AdaptiveReadGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveReadGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveReadGroupBatchSizeRangeRule: AdaptiveReadGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveReadGroup) -> [String] {
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

    final class AdaptiveReadGroupRequiredCodeRule: AdaptiveReadGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveReadGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveReadGroupUnitLengthRule: AdaptiveReadGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReadGroup) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive read group.
    final class AdaptiveReadGroupValidator {
        var rules: [any AdaptiveReadGroupRule]

        init(rules: [any AdaptiveReadGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveReadGroup) -> [String] {
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

        func requireValid(_ item: AdaptiveReadGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveReadGroup]) -> [String: [String]] {
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

    static func defaultAdaptiveReadGroupValidator() -> AdaptiveReadGroupValidator {
        return AdaptiveReadGroupValidator(
            rules: [
                AdaptiveReadGroupBudgetRangeRule(min: 7.6, max: 4821.4),
                AdaptiveReadGroupCodePrefixRule(prefix: "OPS"),
                AdaptiveReadGroupBatchSizeRangeRule(min: 16, max: 255),
                AdaptiveReadGroupRequiredCodeRule(message: "adaptive read group needs an entry"),
                AdaptiveReadGroupUnitLengthRule(maxLength: 120),
            ]
        )
    }
}

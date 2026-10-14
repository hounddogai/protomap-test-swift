import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict proxy target must pass. Check returns its problems, or none.
    protocol StrictProxyTargetRule {
        func check(_ item: StrictProxyTarget) -> [String]
    }

    final class StrictProxyTargetAllowedCodeRule: StrictProxyTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictProxyTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class StrictProxyTargetLabelLengthRule: StrictProxyTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictProxyTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictProxyTargetBudgetRangeRule: StrictProxyTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProxyTarget) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictProxyTargetCodePrefixRule: StrictProxyTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictProxyTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictProxyTargetFloorValueRangeRule: StrictProxyTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProxyTarget) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict proxy target.
    final class StrictProxyTargetValidator {
        var rules: [any StrictProxyTargetRule]

        init(rules: [any StrictProxyTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictProxyTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictProxyTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictProxyTarget]) -> [String: [String]] {
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

    static func defaultStrictProxyTargetValidator() -> StrictProxyTargetValidator {
        return StrictProxyTargetValidator(
            rules: [
                StrictProxyTargetAllowedCodeRule(allowed: []),
                StrictProxyTargetLabelLengthRule(maxLength: 80),
                StrictProxyTargetBudgetRangeRule(min: 0.1, max: 4041.8),
                StrictProxyTargetCodePrefixRule(prefix: "Q"),
                StrictProxyTargetFloorValueRangeRule(min: 8.5, max: 1025.9),
            ]
        )
    }
}

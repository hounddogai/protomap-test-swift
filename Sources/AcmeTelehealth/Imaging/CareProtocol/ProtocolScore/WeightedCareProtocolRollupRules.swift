import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted care protocol rollup must pass. Check returns its problems, or none.
    protocol WeightedCareProtocolRollupRule {
        func check(_ item: WeightedCareProtocolRollup) -> [String]
    }

    final class WeightedCareProtocolRollupAllowedCodeRule: WeightedCareProtocolRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedCareProtocolRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class WeightedCareProtocolRollupDiscountRangeRule: WeightedCareProtocolRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareProtocolRollup) -> [String] {
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

    final class WeightedCareProtocolRollupLabelLengthRule: WeightedCareProtocolRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCareProtocolRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted care protocol rollup.
    final class WeightedCareProtocolRollupValidator {
        var rules: [any WeightedCareProtocolRollupRule]

        init(rules: [any WeightedCareProtocolRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCareProtocolRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCareProtocolRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCareProtocolRollup]) -> [String: [String]] {
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

    static func defaultWeightedCareProtocolRollupValidator() -> WeightedCareProtocolRollupValidator {
        return WeightedCareProtocolRollupValidator(
            rules: [
                WeightedCareProtocolRollupAllowedCodeRule(allowed: ["legacy", "rolling"]),
                WeightedCareProtocolRollupDiscountRangeRule(min: 1.0, max: 1716.9),
                WeightedCareProtocolRollupLabelLengthRule(maxLength: 32),
            ]
        )
    }
}

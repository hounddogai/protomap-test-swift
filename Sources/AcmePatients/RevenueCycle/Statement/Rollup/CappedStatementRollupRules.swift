import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped statement rollup must pass. Check returns its problems, or none.
    protocol CappedStatementRollupRule {
        func check(_ item: CappedStatementRollup) -> [String]
    }

    final class CappedStatementRollupCopayRangeRule: CappedStatementRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedStatementRollup) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedStatementRollupNameLengthRule: CappedStatementRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStatementRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedStatementRollupMinimumRangeRule: CappedStatementRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedStatementRollup) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedStatementRollupCodePrefixRule: CappedStatementRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedStatementRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedStatementRollupCodeLengthRule: CappedStatementRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStatementRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedStatementRollupFloorValueRangeRule: CappedStatementRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedStatementRollup) -> [String] {
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

    /// Runs every rule of a capped statement rollup.
    final class CappedStatementRollupValidator {
        var rules: [any CappedStatementRollupRule]

        init(rules: [any CappedStatementRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedStatementRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedStatementRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedStatementRollup]) -> [String: [String]] {
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

    static func defaultCappedStatementRollupValidator() -> CappedStatementRollupValidator {
        return CappedStatementRollupValidator(
            rules: [
                CappedStatementRollupCopayRangeRule(min: 8.8, max: 3737.5),
                CappedStatementRollupNameLengthRule(maxLength: 16),
                CappedStatementRollupMinimumRangeRule(min: 3.7, max: 2695.6),
                CappedStatementRollupCodePrefixRule(prefix: "OPS"),
                CappedStatementRollupCodeLengthRule(maxLength: 120),
                CappedStatementRollupFloorValueRangeRule(min: 4.1, max: 409.1),
            ]
        )
    }
}

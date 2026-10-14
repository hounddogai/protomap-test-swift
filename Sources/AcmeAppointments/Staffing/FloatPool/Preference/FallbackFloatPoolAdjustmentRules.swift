import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback float pool adjustment must pass. Check returns its problems, or none.
    protocol FallbackFloatPoolAdjustmentRule {
        func check(_ item: FallbackFloatPoolAdjustment) -> [String]
    }

    final class FallbackFloatPoolAdjustmentVersionRangeRule: FallbackFloatPoolAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackFloatPoolAdjustment) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackFloatPoolAdjustmentProcedureCodeLengthRule: FallbackFloatPoolAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackFloatPoolAdjustment) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackFloatPoolAdjustmentCodePrefixRule: FallbackFloatPoolAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackFloatPoolAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackFloatPoolAdjustmentCodeLengthRule: FallbackFloatPoolAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackFloatPoolAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback float pool adjustment.
    final class FallbackFloatPoolAdjustmentValidator {
        var rules: [any FallbackFloatPoolAdjustmentRule]

        init(rules: [any FallbackFloatPoolAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFloatPoolAdjustment) -> [String] {
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

        func requireValid(_ item: FallbackFloatPoolAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFloatPoolAdjustment]) -> [String: [String]] {
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

    static func defaultFallbackFloatPoolAdjustmentValidator() -> FallbackFloatPoolAdjustmentValidator {
        return FallbackFloatPoolAdjustmentValidator(
            rules: [
                FallbackFloatPoolAdjustmentVersionRangeRule(min: 1000, max: 1000),
                FallbackFloatPoolAdjustmentProcedureCodeLengthRule(maxLength: 16),
                FallbackFloatPoolAdjustmentCodePrefixRule(prefix: "ACM"),
                FallbackFloatPoolAdjustmentCodeLengthRule(maxLength: 16),
            ]
        )
    }
}

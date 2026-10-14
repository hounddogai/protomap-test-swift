import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback inventory baseline must pass. Check returns its problems, or none.
    protocol FallbackInventoryBaselineRule {
        func check(_ item: FallbackInventoryBaseline) -> [String]
    }

    final class FallbackInventoryBaselineCodePrefixRule: FallbackInventoryBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackInventoryBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackInventoryBaselineDiscountRangeRule: FallbackInventoryBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackInventoryBaseline) -> [String] {
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

    final class FallbackInventoryBaselineRequiredProcedureCodeRule: FallbackInventoryBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackInventoryBaseline) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackInventoryBaselinePriorityRangeRule: FallbackInventoryBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackInventoryBaseline) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback inventory baseline.
    final class FallbackInventoryBaselineValidator {
        var rules: [any FallbackInventoryBaselineRule]

        init(rules: [any FallbackInventoryBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackInventoryBaseline) -> [String] {
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

        func requireValid(_ item: FallbackInventoryBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackInventoryBaseline]) -> [String: [String]] {
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

    static func defaultFallbackInventoryBaselineValidator() -> FallbackInventoryBaselineValidator {
        return FallbackInventoryBaselineValidator(
            rules: [
                FallbackInventoryBaselineCodePrefixRule(prefix: "X"),
                FallbackInventoryBaselineDiscountRangeRule(min: 6.9, max: 2852.5),
                FallbackInventoryBaselineRequiredProcedureCodeRule(
                    message: "fallback inventory baseline needs an entry"
                ),
                FallbackInventoryBaselinePriorityRangeRule(min: 80, max: 120),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered closure mapping must pass. Check returns its problems, or none.
    protocol TieredClosureMappingRule {
        func check(_ item: TieredClosureMapping) -> [String]
    }

    final class TieredClosureMappingCodeLengthRule: TieredClosureMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClosureMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClosureMappingRequiredCodeRule: TieredClosureMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClosureMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClosureMappingDiscountRangeRule: TieredClosureMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredClosureMapping) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered closure mapping.
    final class TieredClosureMappingValidator {
        var rules: [any TieredClosureMappingRule]

        init(rules: [any TieredClosureMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClosureMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredClosureMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClosureMapping]) -> [String: [String]] {
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

    static func defaultTieredClosureMappingValidator() -> TieredClosureMappingValidator {
        return TieredClosureMappingValidator(
            rules: [
                TieredClosureMappingCodeLengthRule(maxLength: 16),
                TieredClosureMappingRequiredCodeRule(message: "tiered closure mapping needs this field"),
                TieredClosureMappingDiscountRangeRule(min: 6.1, max: 3206.8),
            ]
        )
    }
}

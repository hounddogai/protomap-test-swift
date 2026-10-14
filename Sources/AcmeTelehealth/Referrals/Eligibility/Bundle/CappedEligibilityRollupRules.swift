import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped eligibility rollup must pass. Check returns its problems, or none.
    protocol CappedEligibilityRollupRule {
        func check(_ item: CappedEligibilityRollup) -> [String]
    }

    final class CappedEligibilityRollupDiscountRangeRule: CappedEligibilityRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedEligibilityRollup) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedEligibilityRollupAttemptsRangeRule: CappedEligibilityRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedEligibilityRollup) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedEligibilityRollupLocaleLengthRule: CappedEligibilityRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedEligibilityRollup) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedEligibilityRollupRequiredCodeRule: CappedEligibilityRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedEligibilityRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedEligibilityRollupNameLengthRule: CappedEligibilityRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedEligibilityRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped eligibility rollup.
    final class CappedEligibilityRollupValidator {
        var rules: [any CappedEligibilityRollupRule]

        init(rules: [any CappedEligibilityRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedEligibilityRollup) -> [String] {
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

        func requireValid(_ item: CappedEligibilityRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedEligibilityRollup]) -> [String: [String]] {
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

    static func defaultCappedEligibilityRollupValidator() -> CappedEligibilityRollupValidator {
        return CappedEligibilityRollupValidator(
            rules: [
                CappedEligibilityRollupDiscountRangeRule(min: 6.2, max: 2852.5),
                CappedEligibilityRollupAttemptsRangeRule(min: 32, max: 32),
                CappedEligibilityRollupLocaleLengthRule(maxLength: 16),
                CappedEligibilityRollupRequiredCodeRule(message: "capped eligibility rollup needs a value"),
                CappedEligibilityRollupNameLengthRule(maxLength: 1000),
            ]
        )
    }
}

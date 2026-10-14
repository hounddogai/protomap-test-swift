import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered charge batch must pass. Check returns its problems, or none.
    protocol TieredChargeBatchRule {
        func check(_ item: TieredChargeBatch) -> [String]
    }

    final class TieredChargeBatchCodePrefixRule: TieredChargeBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredChargeBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredChargeBatchLabelLengthRule: TieredChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredChargeBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredChargeBatchCurrencyLengthRule: TieredChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredChargeBatch) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredChargeBatchRequiredLabelRule: TieredChargeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredChargeBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredChargeBatchRequiredCurrencyRule: TieredChargeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredChargeBatch) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredChargeBatchLimitRangeRule: TieredChargeBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredChargeBatch) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered charge batch.
    final class TieredChargeBatchValidator {
        var rules: [any TieredChargeBatchRule]

        init(rules: [any TieredChargeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredChargeBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredChargeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredChargeBatch]) -> [String: [String]] {
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

    static func defaultTieredChargeBatchValidator() -> TieredChargeBatchValidator {
        return TieredChargeBatchValidator(
            rules: [
                TieredChargeBatchCodePrefixRule(prefix: "Q"),
                TieredChargeBatchLabelLengthRule(maxLength: 120),
                TieredChargeBatchCurrencyLengthRule(maxLength: 1000),
                TieredChargeBatchRequiredLabelRule(message: "tiered charge batch needs this field"),
                TieredChargeBatchRequiredCurrencyRule(message: "tiered charge batch needs an entry"),
                TieredChargeBatchLimitRangeRule(min: 16, max: 3600),
            ]
        )
    }
}

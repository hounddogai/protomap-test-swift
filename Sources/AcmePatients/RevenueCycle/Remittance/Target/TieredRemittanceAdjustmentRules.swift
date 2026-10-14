import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered remittance adjustment must pass. Check returns its problems, or none.
    protocol TieredRemittanceAdjustmentRule {
        func check(_ item: TieredRemittanceAdjustment) -> [String]
    }

    final class TieredRemittanceAdjustmentNameLengthRule: TieredRemittanceAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRemittanceAdjustmentCodeLengthRule: TieredRemittanceAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRemittanceAdjustmentPinnedGuardRule: TieredRemittanceAdjustmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredRemittanceAdjustment) -> [String] {
            if item.pinned && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class TieredRemittanceAdjustmentStartsAtRangeRule: TieredRemittanceAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRemittanceAdjustment) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRemittanceAdjustmentRequiredCodeRule: TieredRemittanceAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRemittanceAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRemittanceAdjustmentPayerLengthRule: TieredRemittanceAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceAdjustment) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered remittance adjustment.
    final class TieredRemittanceAdjustmentValidator {
        var rules: [any TieredRemittanceAdjustmentRule]

        init(rules: [any TieredRemittanceAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRemittanceAdjustment) -> [String] {
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

        func requireValid(_ item: TieredRemittanceAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRemittanceAdjustment]) -> [String: [String]] {
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

    static func defaultTieredRemittanceAdjustmentValidator() -> TieredRemittanceAdjustmentValidator {
        return TieredRemittanceAdjustmentValidator(
            rules: [
                TieredRemittanceAdjustmentNameLengthRule(maxLength: 16),
                TieredRemittanceAdjustmentCodeLengthRule(maxLength: 120),
                TieredRemittanceAdjustmentPinnedGuardRule(limit: 80),
                TieredRemittanceAdjustmentStartsAtRangeRule(min: 255, max: 86400),
                TieredRemittanceAdjustmentRequiredCodeRule(message: "tiered remittance adjustment needs this field"),
                TieredRemittanceAdjustmentPayerLengthRule(maxLength: 64),
            ]
        )
    }
}

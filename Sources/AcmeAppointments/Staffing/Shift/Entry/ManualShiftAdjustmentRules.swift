import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual shift adjustment must pass. Check returns its problems, or none.
    protocol ManualShiftAdjustmentRule {
        func check(_ item: ManualShiftAdjustment) -> [String]
    }

    final class ManualShiftAdjustmentVisibleGuardRule: ManualShiftAdjustmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ManualShiftAdjustment) -> [String] {
            if item.visible && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ManualShiftAdjustmentCurrencyLengthRule: ManualShiftAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualShiftAdjustment) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualShiftAdjustmentRequiredCodeRule: ManualShiftAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualShiftAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual shift adjustment.
    final class ManualShiftAdjustmentValidator {
        var rules: [any ManualShiftAdjustmentRule]

        init(rules: [any ManualShiftAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualShiftAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualShiftAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualShiftAdjustment]) -> [String: [String]] {
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

    static func defaultManualShiftAdjustmentValidator() -> ManualShiftAdjustmentValidator {
        return ManualShiftAdjustmentValidator(
            rules: [
                ManualShiftAdjustmentVisibleGuardRule(limit: 64),
                ManualShiftAdjustmentCurrencyLengthRule(maxLength: 64),
                ManualShiftAdjustmentRequiredCodeRule(message: "manual shift adjustment needs a value"),
            ]
        )
    }
}

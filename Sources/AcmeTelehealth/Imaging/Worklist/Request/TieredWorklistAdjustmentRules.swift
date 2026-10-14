import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered worklist adjustment must pass. Check returns its problems, or none.
    protocol TieredWorklistAdjustmentRule {
        func check(_ item: TieredWorklistAdjustment) -> [String]
    }

    final class TieredWorklistAdjustmentRequiredCodeRule: TieredWorklistAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredWorklistAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredWorklistAdjustmentRequiredSpecialtyRule: TieredWorklistAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredWorklistAdjustment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredWorklistAdjustmentNameLengthRule: TieredWorklistAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredWorklistAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredWorklistAdjustmentCodePrefixRule: TieredWorklistAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredWorklistAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredWorklistAdjustmentCodeLengthRule: TieredWorklistAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredWorklistAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredWorklistAdjustmentMarginRangeRule: TieredWorklistAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredWorklistAdjustment) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered worklist adjustment.
    final class TieredWorklistAdjustmentValidator {
        var rules: [any TieredWorklistAdjustmentRule]

        init(rules: [any TieredWorklistAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredWorklistAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredWorklistAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredWorklistAdjustment]) -> [String: [String]] {
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

    static func defaultTieredWorklistAdjustmentValidator() -> TieredWorklistAdjustmentValidator {
        return TieredWorklistAdjustmentValidator(
            rules: [
                TieredWorklistAdjustmentRequiredCodeRule(message: "tiered worklist adjustment needs this field"),
                TieredWorklistAdjustmentRequiredSpecialtyRule(message: "tiered worklist adjustment needs this field"),
                TieredWorklistAdjustmentNameLengthRule(maxLength: 1000),
                TieredWorklistAdjustmentCodePrefixRule(prefix: "ACM"),
                TieredWorklistAdjustmentCodeLengthRule(maxLength: 64),
                TieredWorklistAdjustmentMarginRangeRule(min: 1.1, max: 1460.5),
            ]
        )
    }
}

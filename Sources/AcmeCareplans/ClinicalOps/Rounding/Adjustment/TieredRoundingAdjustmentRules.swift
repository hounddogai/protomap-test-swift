import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered rounding adjustment must pass. Check returns its problems, or none.
    protocol TieredRoundingAdjustmentRule {
        func check(_ item: TieredRoundingAdjustment) -> [String]
    }

    final class TieredRoundingAdjustmentRequiredCodeRule: TieredRoundingAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRoundingAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRoundingAdjustmentThresholdRangeRule: TieredRoundingAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRoundingAdjustment) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRoundingAdjustmentSpecialtyLengthRule: TieredRoundingAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRoundingAdjustment) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered rounding adjustment.
    final class TieredRoundingAdjustmentValidator {
        var rules: [any TieredRoundingAdjustmentRule]

        init(rules: [any TieredRoundingAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRoundingAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRoundingAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRoundingAdjustment]) -> [String: [String]] {
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

    static func defaultTieredRoundingAdjustmentValidator() -> TieredRoundingAdjustmentValidator {
        return TieredRoundingAdjustmentValidator(
            rules: [
                TieredRoundingAdjustmentRequiredCodeRule(message: "tiered rounding adjustment needs a value"),
                TieredRoundingAdjustmentThresholdRangeRule(min: 7.5, max: 2159.9),
                TieredRoundingAdjustmentSpecialtyLengthRule(maxLength: 1000),
            ]
        )
    }
}

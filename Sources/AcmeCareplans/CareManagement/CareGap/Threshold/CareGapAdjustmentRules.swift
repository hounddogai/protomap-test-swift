import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap adjustment must pass. Check returns its problems, or none.
    protocol CareGapAdjustmentRule {
        func check(_ item: CareGapAdjustment) -> [String]
    }

    final class CareGapAdjustmentVersionRangeRule: CareGapAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapAdjustment) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapAdjustmentLabelLengthRule: CareGapAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapAdjustmentRequiredCurrencyRule: CareGapAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapAdjustment) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapAdjustmentSourceLengthRule: CareGapAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapAdjustment) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap adjustment.
    final class CareGapAdjustmentValidator {
        var rules: [any CareGapAdjustmentRule]

        init(rules: [any CareGapAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapAdjustment]) -> [String: [String]] {
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

    static func defaultCareGapAdjustmentValidator() -> CareGapAdjustmentValidator {
        return CareGapAdjustmentValidator(
            rules: [
                CareGapAdjustmentVersionRangeRule(min: 32, max: 255),
                CareGapAdjustmentLabelLengthRule(maxLength: 255),
                CareGapAdjustmentRequiredCurrencyRule(message: "care gap adjustment needs a value"),
                CareGapAdjustmentSourceLengthRule(maxLength: 64),
            ]
        )
    }
}

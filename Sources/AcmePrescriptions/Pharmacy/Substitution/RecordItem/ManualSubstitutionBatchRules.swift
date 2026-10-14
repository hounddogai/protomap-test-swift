import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual substitution batch must pass. Check returns its problems, or none.
    protocol ManualSubstitutionBatchRule {
        func check(_ item: ManualSubstitutionBatch) -> [String]
    }

    final class ManualSubstitutionBatchDiscountRangeRule: ManualSubstitutionBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualSubstitutionBatch) -> [String] {
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

    final class ManualSubstitutionBatchRequiredPhoneRule: ManualSubstitutionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSubstitutionBatch) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualSubstitutionBatchPhoneLengthRule: ManualSubstitutionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSubstitutionBatch) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSubstitutionBatchCodeLengthRule: ManualSubstitutionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSubstitutionBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSubstitutionBatchRequiredCodeRule: ManualSubstitutionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSubstitutionBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual substitution batch.
    final class ManualSubstitutionBatchValidator {
        var rules: [any ManualSubstitutionBatchRule]

        init(rules: [any ManualSubstitutionBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualSubstitutionBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualSubstitutionBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualSubstitutionBatch]) -> [String: [String]] {
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

    static func defaultManualSubstitutionBatchValidator() -> ManualSubstitutionBatchValidator {
        return ManualSubstitutionBatchValidator(
            rules: [
                ManualSubstitutionBatchDiscountRangeRule(min: 2.2, max: 4505.7),
                ManualSubstitutionBatchRequiredPhoneRule(message: "manual substitution batch needs this field"),
                ManualSubstitutionBatchPhoneLengthRule(maxLength: 1000),
                ManualSubstitutionBatchCodeLengthRule(maxLength: 1000),
                ManualSubstitutionBatchRequiredCodeRule(message: "manual substitution batch needs this field"),
            ]
        )
    }
}

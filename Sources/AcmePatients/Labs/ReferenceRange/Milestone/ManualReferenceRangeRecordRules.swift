import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual reference range record must pass. Check returns its problems, or none.
    protocol ManualReferenceRangeRecordRule {
        func check(_ item: ManualReferenceRangeRecord) -> [String]
    }

    final class ManualReferenceRangeRecordRequiredCodeRule: ManualReferenceRangeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReferenceRangeRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReferenceRangeRecordCodeLengthRule: ManualReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReferenceRangeRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReferenceRangeRecordLabelLengthRule: ManualReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReferenceRangeRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReferenceRangeRecordDiscountRangeRule: ManualReferenceRangeRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualReferenceRangeRecord) -> [String] {
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

    final class ManualReferenceRangeRecordTitleLengthRule: ManualReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReferenceRangeRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReferenceRangeRecordRequiredLabelRule: ManualReferenceRangeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReferenceRangeRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual reference range record.
    final class ManualReferenceRangeRecordValidator {
        var rules: [any ManualReferenceRangeRecordRule]

        init(rules: [any ManualReferenceRangeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualReferenceRangeRecord) -> [String] {
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

        func requireValid(_ item: ManualReferenceRangeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualReferenceRangeRecord]) -> [String: [String]] {
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

    static func defaultManualReferenceRangeRecordValidator() -> ManualReferenceRangeRecordValidator {
        return ManualReferenceRangeRecordValidator(
            rules: [
                ManualReferenceRangeRecordRequiredCodeRule(message: "manual reference range record needs an entry"),
                ManualReferenceRangeRecordCodeLengthRule(maxLength: 120),
                ManualReferenceRangeRecordLabelLengthRule(maxLength: 86400),
                ManualReferenceRangeRecordDiscountRangeRule(min: 7.0, max: 901.0),
                ManualReferenceRangeRecordTitleLengthRule(maxLength: 80),
                ManualReferenceRangeRecordRequiredLabelRule(message: "manual reference range record needs this field"),
            ]
        )
    }
}

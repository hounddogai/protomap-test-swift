import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped substitution record must pass. Check returns its problems, or none.
    protocol CappedSubstitutionRecordRule {
        func check(_ item: CappedSubstitutionRecord) -> [String]
    }

    final class CappedSubstitutionRecordLabelLengthRule: CappedSubstitutionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSubstitutionRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSubstitutionRecordCopayRangeRule: CappedSubstitutionRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSubstitutionRecord) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedSubstitutionRecordCodeLengthRule: CappedSubstitutionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSubstitutionRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSubstitutionRecordRevisionRangeRule: CappedSubstitutionRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSubstitutionRecord) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped substitution record.
    final class CappedSubstitutionRecordValidator {
        var rules: [any CappedSubstitutionRecordRule]

        init(rules: [any CappedSubstitutionRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSubstitutionRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedSubstitutionRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSubstitutionRecord]) -> [String: [String]] {
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

    static func defaultCappedSubstitutionRecordValidator() -> CappedSubstitutionRecordValidator {
        return CappedSubstitutionRecordValidator(
            rules: [
                CappedSubstitutionRecordLabelLengthRule(maxLength: 64),
                CappedSubstitutionRecordCopayRangeRule(min: 5.8, max: 442.3),
                CappedSubstitutionRecordCodeLengthRule(maxLength: 16),
                CappedSubstitutionRecordRevisionRangeRule(min: 64, max: 1000),
            ]
        )
    }
}

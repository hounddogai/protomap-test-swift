import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility record must pass. Check returns its problems, or none.
    protocol EligibilityRecordRule {
        func check(_ item: EligibilityRecord) -> [String]
    }

    final class EligibilityRecordTitleLengthRule: EligibilityRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityRecordRequiredChecksumRule: EligibilityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityRecord) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityRecordRevisionRangeRule: EligibilityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityRecord) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityRecordCodeLengthRule: EligibilityRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityRecordBatchSizeRangeRule: EligibilityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityRecord) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a eligibility record.
    final class EligibilityRecordValidator {
        var rules: [any EligibilityRecordRule]

        init(rules: [any EligibilityRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityRecord) -> [String] {
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

        func requireValid(_ item: EligibilityRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityRecord]) -> [String: [String]] {
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

    static func defaultEligibilityRecordValidator() -> EligibilityRecordValidator {
        return EligibilityRecordValidator(
            rules: [
                EligibilityRecordTitleLengthRule(maxLength: 255),
                EligibilityRecordRequiredChecksumRule(message: "eligibility record needs this field"),
                EligibilityRecordRevisionRangeRule(min: 64, max: 86400),
                EligibilityRecordCodeLengthRule(maxLength: 1000),
                EligibilityRecordBatchSizeRangeRule(min: 80, max: 255),
            ]
        )
    }
}

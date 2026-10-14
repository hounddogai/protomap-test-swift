import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal eligibility record must pass. Check returns its problems, or none.
    protocol SeasonalEligibilityRecordRule {
        func check(_ item: SeasonalEligibilityRecord) -> [String]
    }

    final class SeasonalEligibilityRecordPatientRefLengthRule: SeasonalEligibilityRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalEligibilityRecord) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalEligibilityRecordRequiredTitleRule: SeasonalEligibilityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalEligibilityRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalEligibilityRecordRequiredPatientRefRule: SeasonalEligibilityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalEligibilityRecord) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalEligibilityRecordGraceDaysRangeRule: SeasonalEligibilityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalEligibilityRecord) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalEligibilityRecordBatchSizeRangeRule: SeasonalEligibilityRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalEligibilityRecord) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal eligibility record.
    final class SeasonalEligibilityRecordValidator {
        var rules: [any SeasonalEligibilityRecordRule]

        init(rules: [any SeasonalEligibilityRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalEligibilityRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalEligibilityRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalEligibilityRecord]) -> [String: [String]] {
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

    static func defaultSeasonalEligibilityRecordValidator() -> SeasonalEligibilityRecordValidator {
        return SeasonalEligibilityRecordValidator(
            rules: [
                SeasonalEligibilityRecordPatientRefLengthRule(maxLength: 16),
                SeasonalEligibilityRecordRequiredTitleRule(message: "seasonal eligibility record needs this field"),
                SeasonalEligibilityRecordRequiredPatientRefRule(message: "seasonal eligibility record needs a value"),
                SeasonalEligibilityRecordGraceDaysRangeRule(min: 120, max: 3600),
                SeasonalEligibilityRecordBatchSizeRangeRule(min: 80, max: 255),
            ]
        )
    }
}

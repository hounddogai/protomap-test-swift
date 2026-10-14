import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal assessment snapshot must pass. Check returns its problems, or none.
    protocol SeasonalAssessmentSnapshotRule {
        func check(_ item: SeasonalAssessmentSnapshot) -> [String]
    }

    final class SeasonalAssessmentSnapshotRequiredCodeRule: SeasonalAssessmentSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAssessmentSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalAssessmentSnapshotBatchSizeRangeRule: SeasonalAssessmentSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAssessmentSnapshot) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalAssessmentSnapshotGraceDaysRangeRule: SeasonalAssessmentSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAssessmentSnapshot) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalAssessmentSnapshotRateRangeRule: SeasonalAssessmentSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAssessmentSnapshot) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal assessment snapshot.
    final class SeasonalAssessmentSnapshotValidator {
        var rules: [any SeasonalAssessmentSnapshotRule]

        init(rules: [any SeasonalAssessmentSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAssessmentSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalAssessmentSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAssessmentSnapshot]) -> [String: [String]] {
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

    static func defaultSeasonalAssessmentSnapshotValidator() -> SeasonalAssessmentSnapshotValidator {
        return SeasonalAssessmentSnapshotValidator(
            rules: [
                SeasonalAssessmentSnapshotRequiredCodeRule(message: "seasonal assessment snapshot needs this field"),
                SeasonalAssessmentSnapshotBatchSizeRangeRule(min: 80, max: 86400),
                SeasonalAssessmentSnapshotGraceDaysRangeRule(min: 32, max: 32),
                SeasonalAssessmentSnapshotRateRangeRule(min: 4.0, max: 3564.2),
            ]
        )
    }
}

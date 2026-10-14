import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling accession record must pass. Check returns its problems, or none.
    protocol RollingAccessionRecordRule {
        func check(_ item: RollingAccessionRecord) -> [String]
    }

    final class RollingAccessionRecordBudgetRangeRule: RollingAccessionRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAccessionRecord) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingAccessionRecordBatchSizeRangeRule: RollingAccessionRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAccessionRecord) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingAccessionRecordRequiredNameRule: RollingAccessionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling accession record.
    final class RollingAccessionRecordValidator {
        var rules: [any RollingAccessionRecordRule]

        init(rules: [any RollingAccessionRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAccessionRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAccessionRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAccessionRecord]) -> [String: [String]] {
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

    static func defaultRollingAccessionRecordValidator() -> RollingAccessionRecordValidator {
        return RollingAccessionRecordValidator(
            rules: [
                RollingAccessionRecordBudgetRangeRule(min: 2.2, max: 2400.8),
                RollingAccessionRecordBatchSizeRangeRule(min: 120, max: 255),
                RollingAccessionRecordRequiredNameRule(message: "rolling accession record needs a value"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional skill mix ledger must pass. Check returns its problems, or none.
    protocol RegionalSkillMixLedgerRule {
        func check(_ item: RegionalSkillMixLedger) -> [String]
    }

    final class RegionalSkillMixLedgerScoreRangeRule: RegionalSkillMixLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSkillMixLedger) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalSkillMixLedgerBatchSizeRangeRule: RegionalSkillMixLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSkillMixLedger) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalSkillMixLedgerTitleLengthRule: RegionalSkillMixLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSkillMixLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSkillMixLedgerSequenceRangeRule: RegionalSkillMixLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSkillMixLedger) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalSkillMixLedgerCodeLengthRule: RegionalSkillMixLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSkillMixLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional skill mix ledger.
    final class RegionalSkillMixLedgerValidator {
        var rules: [any RegionalSkillMixLedgerRule]

        init(rules: [any RegionalSkillMixLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSkillMixLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSkillMixLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSkillMixLedger]) -> [String: [String]] {
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

    static func defaultRegionalSkillMixLedgerValidator() -> RegionalSkillMixLedgerValidator {
        return RegionalSkillMixLedgerValidator(
            rules: [
                RegionalSkillMixLedgerScoreRangeRule(min: 5.5, max: 2353.9),
                RegionalSkillMixLedgerBatchSizeRangeRule(min: 64, max: 80),
                RegionalSkillMixLedgerTitleLengthRule(maxLength: 255),
                RegionalSkillMixLedgerSequenceRangeRule(min: 16, max: 80),
                RegionalSkillMixLedgerCodeLengthRule(maxLength: 255),
            ]
        )
    }
}

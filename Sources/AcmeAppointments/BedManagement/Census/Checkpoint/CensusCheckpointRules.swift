import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census checkpoint must pass. Check returns its problems, or none.
    protocol CensusCheckpointRule {
        func check(_ item: CensusCheckpoint) -> [String]
    }

    final class CensusCheckpointCodeLengthRule: CensusCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusCheckpointCeilingRangeRule: CensusCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusCheckpoint) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusCheckpointLabelLengthRule: CensusCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusCheckpointBudgetRangeRule: CensusCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusCheckpoint) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a census checkpoint.
    final class CensusCheckpointValidator {
        var rules: [any CensusCheckpointRule]

        init(rules: [any CensusCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusCheckpoint) -> [String] {
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

        func requireValid(_ item: CensusCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusCheckpoint]) -> [String: [String]] {
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

    static func defaultCensusCheckpointValidator() -> CensusCheckpointValidator {
        return CensusCheckpointValidator(
            rules: [
                CensusCheckpointCodeLengthRule(maxLength: 86400),
                CensusCheckpointCeilingRangeRule(min: 5.5, max: 4150.1),
                CensusCheckpointLabelLengthRule(maxLength: 255),
                CensusCheckpointBudgetRangeRule(min: 8.7, max: 1593.8),
            ]
        )
    }
}

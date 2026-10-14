import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap rollup must pass. Check returns its problems, or none.
    protocol CareGapRollupRule {
        func check(_ item: CareGapRollup) -> [String]
    }

    final class CareGapRollupProcedureCodeLengthRule: CareGapRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapRollup) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapRollupLimitRangeRule: CareGapRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapRollup) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapRollupCodeLengthRule: CareGapRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap rollup.
    final class CareGapRollupValidator {
        var rules: [any CareGapRollupRule]

        init(rules: [any CareGapRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapRollup]) -> [String: [String]] {
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

    static func defaultCareGapRollupValidator() -> CareGapRollupValidator {
        return CareGapRollupValidator(
            rules: [
                CareGapRollupProcedureCodeLengthRule(maxLength: 80),
                CareGapRollupLimitRangeRule(min: 32, max: 3600),
                CareGapRollupCodeLengthRule(maxLength: 32),
            ]
        )
    }
}

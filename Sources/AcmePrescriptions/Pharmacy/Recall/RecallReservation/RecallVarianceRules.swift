import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall variance must pass. Check returns its problems, or none.
    protocol RecallVarianceRule {
        func check(_ item: RecallVariance) -> [String]
    }

    final class RecallVariancePayerLengthRule: RecallVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallVariance) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallVarianceCodeLengthRule: RecallVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallVarianceAttemptsRangeRule: RecallVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallVariance) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a recall variance.
    final class RecallVarianceValidator {
        var rules: [any RecallVarianceRule]

        init(rules: [any RecallVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallVariance) -> [String] {
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

        func requireValid(_ item: RecallVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallVariance]) -> [String: [String]] {
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

    static func defaultRecallVarianceValidator() -> RecallVarianceValidator {
        return RecallVarianceValidator(
            rules: [
                RecallVariancePayerLengthRule(maxLength: 64),
                RecallVarianceCodeLengthRule(maxLength: 1000),
                RecallVarianceAttemptsRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}

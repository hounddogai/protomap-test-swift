import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy program variance must pass. Check returns its problems, or none.
    protocol LegacyProgramVarianceRule {
        func check(_ item: LegacyProgramVariance) -> [String]
    }

    final class LegacyProgramVarianceCodeLengthRule: LegacyProgramVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyProgramVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyProgramVarianceRevisionRangeRule: LegacyProgramVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyProgramVariance) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyProgramVarianceRequiredCodeRule: LegacyProgramVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyProgramVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy program variance.
    final class LegacyProgramVarianceValidator {
        var rules: [any LegacyProgramVarianceRule]

        init(rules: [any LegacyProgramVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyProgramVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyProgramVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyProgramVariance]) -> [String: [String]] {
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

    static func defaultLegacyProgramVarianceValidator() -> LegacyProgramVarianceValidator {
        return LegacyProgramVarianceValidator(
            rules: [
                LegacyProgramVarianceCodeLengthRule(maxLength: 64),
                LegacyProgramVarianceRevisionRangeRule(min: 120, max: 1000),
                LegacyProgramVarianceRequiredCodeRule(message: "legacy program variance needs this field"),
            ]
        )
    }
}

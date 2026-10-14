import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy result variance must pass. Check returns its problems, or none.
    protocol LegacyResultVarianceRule {
        func check(_ item: LegacyResultVariance) -> [String]
    }

    final class LegacyResultVarianceCategoryLengthRule: LegacyResultVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyResultVariance) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyResultVarianceExpiresAtRangeRule: LegacyResultVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyResultVariance) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyResultVarianceRequiredTitleRule: LegacyResultVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyResultVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy result variance.
    final class LegacyResultVarianceValidator {
        var rules: [any LegacyResultVarianceRule]

        init(rules: [any LegacyResultVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyResultVariance) -> [String] {
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

        func requireValid(_ item: LegacyResultVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyResultVariance]) -> [String: [String]] {
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

    static func defaultLegacyResultVarianceValidator() -> LegacyResultVarianceValidator {
        return LegacyResultVarianceValidator(
            rules: [
                LegacyResultVarianceCategoryLengthRule(maxLength: 80),
                LegacyResultVarianceExpiresAtRangeRule(min: 32, max: 32),
                LegacyResultVarianceRequiredTitleRule(message: "legacy result variance needs this field"),
            ]
        )
    }
}

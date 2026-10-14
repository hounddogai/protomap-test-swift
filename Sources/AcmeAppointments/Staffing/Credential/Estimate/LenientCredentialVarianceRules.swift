import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient credential variance must pass. Check returns its problems, or none.
    protocol LenientCredentialVarianceRule {
        func check(_ item: LenientCredentialVariance) -> [String]
    }

    final class LenientCredentialVariancePriorityRangeRule: LenientCredentialVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCredentialVariance) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientCredentialVarianceThresholdRangeRule: LenientCredentialVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCredentialVariance) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientCredentialVarianceLabelLengthRule: LenientCredentialVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCredentialVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCredentialVarianceRequiredWardRule: LenientCredentialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCredentialVariance) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient credential variance.
    final class LenientCredentialVarianceValidator {
        var rules: [any LenientCredentialVarianceRule]

        init(rules: [any LenientCredentialVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCredentialVariance) -> [String] {
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

        func requireValid(_ item: LenientCredentialVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCredentialVariance]) -> [String: [String]] {
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

    static func defaultLenientCredentialVarianceValidator() -> LenientCredentialVarianceValidator {
        return LenientCredentialVarianceValidator(
            rules: [
                LenientCredentialVariancePriorityRangeRule(min: 3600, max: 3600),
                LenientCredentialVarianceThresholdRangeRule(min: 10.0, max: 350.7),
                LenientCredentialVarianceLabelLengthRule(maxLength: 80),
                LenientCredentialVarianceRequiredWardRule(message: "lenient credential variance needs a value"),
            ]
        )
    }
}

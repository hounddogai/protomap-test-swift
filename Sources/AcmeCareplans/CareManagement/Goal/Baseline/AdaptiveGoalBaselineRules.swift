import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive goal baseline must pass. Check returns its problems, or none.
    protocol AdaptiveGoalBaselineRule {
        func check(_ item: AdaptiveGoalBaseline) -> [String]
    }

    final class AdaptiveGoalBaselinePatientRefLengthRule: AdaptiveGoalBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveGoalBaseline) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveGoalBaselineDiscountRangeRule: AdaptiveGoalBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveGoalBaseline) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveGoalBaselineRequiredTitleRule: AdaptiveGoalBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveGoalBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveGoalBaselineCodePrefixRule: AdaptiveGoalBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveGoalBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive goal baseline.
    final class AdaptiveGoalBaselineValidator {
        var rules: [any AdaptiveGoalBaselineRule]

        init(rules: [any AdaptiveGoalBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveGoalBaseline) -> [String] {
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

        func requireValid(_ item: AdaptiveGoalBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveGoalBaseline]) -> [String: [String]] {
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

    static func defaultAdaptiveGoalBaselineValidator() -> AdaptiveGoalBaselineValidator {
        return AdaptiveGoalBaselineValidator(
            rules: [
                AdaptiveGoalBaselinePatientRefLengthRule(maxLength: 1000),
                AdaptiveGoalBaselineDiscountRangeRule(min: 5.5, max: 3984.0),
                AdaptiveGoalBaselineRequiredTitleRule(message: "adaptive goal baseline needs a value"),
                AdaptiveGoalBaselineCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}

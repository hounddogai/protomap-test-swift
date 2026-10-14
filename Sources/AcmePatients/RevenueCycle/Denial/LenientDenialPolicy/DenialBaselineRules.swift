import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial baseline must pass. Check returns its problems, or none.
    protocol DenialBaselineRule {
        func check(_ item: DenialBaseline) -> [String]
    }

    final class DenialBaselineRevisionRangeRule: DenialBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialBaseline) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialBaselineLabelLengthRule: DenialBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialBaselineSummaryLengthRule: DenialBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialBaseline) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialBaselineRequiredLabelRule: DenialBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial baseline.
    final class DenialBaselineValidator {
        var rules: [any DenialBaselineRule]

        init(rules: [any DenialBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialBaseline]) -> [String: [String]] {
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

    static func defaultDenialBaselineValidator() -> DenialBaselineValidator {
        return DenialBaselineValidator(
            rules: [
                DenialBaselineRevisionRangeRule(min: 16, max: 32),
                DenialBaselineLabelLengthRule(maxLength: 80),
                DenialBaselineSummaryLengthRule(maxLength: 1000),
                DenialBaselineRequiredLabelRule(message: "denial baseline needs this field"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal handoff threshold must pass. Check returns its problems, or none.
    protocol SeasonalHandoffThresholdRule {
        func check(_ item: SeasonalHandoffThreshold) -> [String]
    }

    final class SeasonalHandoffThresholdRequiredCodeRule: SeasonalHandoffThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalHandoffThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalHandoffThresholdCodeLengthRule: SeasonalHandoffThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffThresholdLabelLengthRule: SeasonalHandoffThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffThresholdRetriesRangeRule: SeasonalHandoffThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalHandoffThreshold) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalHandoffThresholdAllowedLabelRule: SeasonalHandoffThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalHandoffThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal handoff threshold.
    final class SeasonalHandoffThresholdValidator {
        var rules: [any SeasonalHandoffThresholdRule]

        init(rules: [any SeasonalHandoffThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalHandoffThreshold) -> [String] {
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

        func requireValid(_ item: SeasonalHandoffThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalHandoffThreshold]) -> [String: [String]] {
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

    static func defaultSeasonalHandoffThresholdValidator() -> SeasonalHandoffThresholdValidator {
        return SeasonalHandoffThresholdValidator(
            rules: [
                SeasonalHandoffThresholdRequiredCodeRule(message: "seasonal handoff threshold needs this field"),
                SeasonalHandoffThresholdCodeLengthRule(maxLength: 3600),
                SeasonalHandoffThresholdLabelLengthRule(maxLength: 64),
                SeasonalHandoffThresholdRetriesRangeRule(min: 80, max: 1000),
                SeasonalHandoffThresholdAllowedLabelRule(allowed: ["capped", "lenient", "rolling"]),
            ]
        )
    }
}

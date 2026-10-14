import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive risk score threshold must pass. Check returns its problems, or none.
    protocol AdaptiveRiskScoreThresholdRule {
        func check(_ item: AdaptiveRiskScoreThreshold) -> [String]
    }

    final class AdaptiveRiskScoreThresholdTitleLengthRule: AdaptiveRiskScoreThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreThresholdRevisionRangeRule: AdaptiveRiskScoreThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRiskScoreThreshold) -> [String] {
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

    final class AdaptiveRiskScoreThresholdCodePrefixRule: AdaptiveRiskScoreThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveRiskScoreThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreThresholdRequiredTitleRule: AdaptiveRiskScoreThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRiskScoreThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreThresholdWardLengthRule: AdaptiveRiskScoreThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreThreshold) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive risk score threshold.
    final class AdaptiveRiskScoreThresholdValidator {
        var rules: [any AdaptiveRiskScoreThresholdRule]

        init(rules: [any AdaptiveRiskScoreThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRiskScoreThreshold) -> [String] {
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

        func requireValid(_ item: AdaptiveRiskScoreThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRiskScoreThreshold]) -> [String: [String]] {
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

    static func defaultAdaptiveRiskScoreThresholdValidator() -> AdaptiveRiskScoreThresholdValidator {
        return AdaptiveRiskScoreThresholdValidator(
            rules: [
                AdaptiveRiskScoreThresholdTitleLengthRule(maxLength: 255),
                AdaptiveRiskScoreThresholdRevisionRangeRule(min: 80, max: 80),
                AdaptiveRiskScoreThresholdCodePrefixRule(prefix: "OPS"),
                AdaptiveRiskScoreThresholdRequiredTitleRule(message: "adaptive risk score threshold needs a value"),
                AdaptiveRiskScoreThresholdWardLengthRule(maxLength: 3600),
            ]
        )
    }
}

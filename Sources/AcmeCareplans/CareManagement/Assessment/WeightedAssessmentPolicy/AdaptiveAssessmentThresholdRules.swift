import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive assessment threshold must pass. Check returns its problems, or none.
    protocol AdaptiveAssessmentThresholdRule {
        func check(_ item: AdaptiveAssessmentThreshold) -> [String]
    }

    final class AdaptiveAssessmentThresholdCopayRangeRule: AdaptiveAssessmentThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAssessmentThreshold) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentThresholdTitleLengthRule: AdaptiveAssessmentThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAssessmentThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentThresholdAllowedCodeRule: AdaptiveAssessmentThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveAssessmentThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentThresholdChannelLengthRule: AdaptiveAssessmentThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAssessmentThreshold) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentThresholdRequiredChannelRule: AdaptiveAssessmentThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAssessmentThreshold) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive assessment threshold.
    final class AdaptiveAssessmentThresholdValidator {
        var rules: [any AdaptiveAssessmentThresholdRule]

        init(rules: [any AdaptiveAssessmentThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAssessmentThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveAssessmentThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAssessmentThreshold]) -> [String: [String]] {
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

    static func defaultAdaptiveAssessmentThresholdValidator() -> AdaptiveAssessmentThresholdValidator {
        return AdaptiveAssessmentThresholdValidator(
            rules: [
                AdaptiveAssessmentThresholdCopayRangeRule(min: 5.8, max: 3466.3),
                AdaptiveAssessmentThresholdTitleLengthRule(maxLength: 16),
                AdaptiveAssessmentThresholdAllowedCodeRule(allowed: ["rolling", "seasonal", "strict"]),
                AdaptiveAssessmentThresholdChannelLengthRule(maxLength: 32),
                AdaptiveAssessmentThresholdRequiredChannelRule(message: "adaptive assessment threshold needs a value"),
            ]
        )
    }
}

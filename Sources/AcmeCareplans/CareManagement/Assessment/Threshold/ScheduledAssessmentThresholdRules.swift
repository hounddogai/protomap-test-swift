import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled assessment threshold must pass. Check returns its problems, or none.
    protocol ScheduledAssessmentThresholdRule {
        func check(_ item: ScheduledAssessmentThreshold) -> [String]
    }

    final class ScheduledAssessmentThresholdTitleLengthRule: ScheduledAssessmentThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAssessmentThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAssessmentThresholdRequiredChannelRule: ScheduledAssessmentThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAssessmentThreshold) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAssessmentThresholdCodePrefixRule: ScheduledAssessmentThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledAssessmentThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledAssessmentThresholdRequiredFacilityRule: ScheduledAssessmentThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAssessmentThreshold) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAssessmentThresholdAllowedTitleRule: ScheduledAssessmentThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledAssessmentThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class ScheduledAssessmentThresholdEndsAtRangeRule: ScheduledAssessmentThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAssessmentThreshold) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled assessment threshold.
    final class ScheduledAssessmentThresholdValidator {
        var rules: [any ScheduledAssessmentThresholdRule]

        init(rules: [any ScheduledAssessmentThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAssessmentThreshold) -> [String] {
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

        func requireValid(_ item: ScheduledAssessmentThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAssessmentThreshold]) -> [String: [String]] {
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

    static func defaultScheduledAssessmentThresholdValidator() -> ScheduledAssessmentThresholdValidator {
        return ScheduledAssessmentThresholdValidator(
            rules: [
                ScheduledAssessmentThresholdTitleLengthRule(maxLength: 255),
                ScheduledAssessmentThresholdRequiredChannelRule(
                    message: "scheduled assessment threshold needs this field"
                ),
                ScheduledAssessmentThresholdCodePrefixRule(prefix: "REF"),
                ScheduledAssessmentThresholdRequiredFacilityRule(
                    message: "scheduled assessment threshold needs this field"
                ),
                ScheduledAssessmentThresholdAllowedTitleRule(allowed: []),
                ScheduledAssessmentThresholdEndsAtRangeRule(min: 16, max: 255),
            ]
        )
    }
}

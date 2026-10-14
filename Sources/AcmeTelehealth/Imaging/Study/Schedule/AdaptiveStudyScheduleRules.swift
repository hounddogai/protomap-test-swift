import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive study schedule must pass. Check returns its problems, or none.
    protocol AdaptiveStudyScheduleRule {
        func check(_ item: AdaptiveStudySchedule) -> [String]
    }

    final class AdaptiveStudyScheduleBatchSizeRangeRule: AdaptiveStudyScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveStudySchedule) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveStudyScheduleNameLengthRule: AdaptiveStudyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStudySchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStudyScheduleRequiredNameRule: AdaptiveStudyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveStudySchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveStudyScheduleAllowedSummaryRule: AdaptiveStudyScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveStudySchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive study schedule.
    final class AdaptiveStudyScheduleValidator {
        var rules: [any AdaptiveStudyScheduleRule]

        init(rules: [any AdaptiveStudyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveStudySchedule) -> [String] {
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

        func requireValid(_ item: AdaptiveStudySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveStudySchedule]) -> [String: [String]] {
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

    static func defaultAdaptiveStudyScheduleValidator() -> AdaptiveStudyScheduleValidator {
        return AdaptiveStudyScheduleValidator(
            rules: [
                AdaptiveStudyScheduleBatchSizeRangeRule(min: 32, max: 255),
                AdaptiveStudyScheduleNameLengthRule(maxLength: 16),
                AdaptiveStudyScheduleRequiredNameRule(message: "adaptive study schedule needs this field"),
                AdaptiveStudyScheduleAllowedSummaryRule(allowed: ["manual", "primary"]),
            ]
        )
    }
}

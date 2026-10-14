import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered care gap schedule must pass. Check returns its problems, or none.
    protocol TieredCareGapScheduleRule {
        func check(_ item: TieredCareGapSchedule) -> [String]
    }

    final class TieredCareGapScheduleRatioRangeRule: TieredCareGapScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareGapSchedule) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredCareGapScheduleRequiredChecksumRule: TieredCareGapScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareGapSchedule) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareGapScheduleAllowedCodeRule: TieredCareGapScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredCareGapSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class TieredCareGapSchedulePriorityRangeRule: TieredCareGapScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareGapSchedule) -> [String] {
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

    final class TieredCareGapScheduleCodePrefixRule: TieredCareGapScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredCareGapSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredCareGapScheduleLabelLengthRule: TieredCareGapScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareGapSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care gap schedule.
    final class TieredCareGapScheduleValidator {
        var rules: [any TieredCareGapScheduleRule]

        init(rules: [any TieredCareGapScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareGapSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCareGapSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareGapSchedule]) -> [String: [String]] {
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

    static func defaultTieredCareGapScheduleValidator() -> TieredCareGapScheduleValidator {
        return TieredCareGapScheduleValidator(
            rules: [
                TieredCareGapScheduleRatioRangeRule(min: 7.9, max: 796.8),
                TieredCareGapScheduleRequiredChecksumRule(message: "tiered care gap schedule needs an entry"),
                TieredCareGapScheduleAllowedCodeRule(allowed: ["lenient", "lenient"]),
                TieredCareGapSchedulePriorityRangeRule(min: 1000, max: 1000),
                TieredCareGapScheduleCodePrefixRule(prefix: "REF"),
                TieredCareGapScheduleLabelLengthRule(maxLength: 120),
            ]
        )
    }
}

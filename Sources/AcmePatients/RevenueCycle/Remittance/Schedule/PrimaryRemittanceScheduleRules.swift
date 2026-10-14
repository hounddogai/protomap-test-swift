import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary remittance schedule must pass. Check returns its problems, or none.
    protocol PrimaryRemittanceScheduleRule {
        func check(_ item: PrimaryRemittanceSchedule) -> [String]
    }

    final class PrimaryRemittanceScheduleTitleLengthRule: PrimaryRemittanceScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRemittanceSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRemittanceScheduleReviewerLengthRule: PrimaryRemittanceScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRemittanceSchedule) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRemittanceScheduleMarginRangeRule: PrimaryRemittanceScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRemittanceSchedule) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryRemittanceScheduleCodeLengthRule: PrimaryRemittanceScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRemittanceSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRemittanceScheduleRequiredCodeRule: PrimaryRemittanceScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRemittanceSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRemittanceScheduleVisibleGuardRule: PrimaryRemittanceScheduleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryRemittanceSchedule) -> [String] {
            if item.visible && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a primary remittance schedule.
    final class PrimaryRemittanceScheduleValidator {
        var rules: [any PrimaryRemittanceScheduleRule]

        init(rules: [any PrimaryRemittanceScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRemittanceSchedule) -> [String] {
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

        func requireValid(_ item: PrimaryRemittanceSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRemittanceSchedule]) -> [String: [String]] {
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

    static func defaultPrimaryRemittanceScheduleValidator() -> PrimaryRemittanceScheduleValidator {
        return PrimaryRemittanceScheduleValidator(
            rules: [
                PrimaryRemittanceScheduleTitleLengthRule(maxLength: 1000),
                PrimaryRemittanceScheduleReviewerLengthRule(maxLength: 80),
                PrimaryRemittanceScheduleMarginRangeRule(min: 7.8, max: 2134.8),
                PrimaryRemittanceScheduleCodeLengthRule(maxLength: 32),
                PrimaryRemittanceScheduleRequiredCodeRule(message: "primary remittance schedule needs this field"),
                PrimaryRemittanceScheduleVisibleGuardRule(limit: 3.9),
            ]
        )
    }
}

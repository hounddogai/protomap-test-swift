import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy float pool schedule must pass. Check returns its problems, or none.
    protocol LegacyFloatPoolScheduleRule {
        func check(_ item: LegacyFloatPoolSchedule) -> [String]
    }

    final class LegacyFloatPoolScheduleOwnerIDLengthRule: LegacyFloatPoolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFloatPoolSchedule) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyFloatPoolScheduleRefillsRangeRule: LegacyFloatPoolScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyFloatPoolSchedule) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyFloatPoolScheduleCodeLengthRule: LegacyFloatPoolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFloatPoolSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyFloatPoolScheduleRequiredSummaryRule: LegacyFloatPoolScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFloatPoolSchedule) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyFloatPoolScheduleApprovedGuardRule: LegacyFloatPoolScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LegacyFloatPoolSchedule) -> [String] {
            if item.approved && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy float pool schedule.
    final class LegacyFloatPoolScheduleValidator {
        var rules: [any LegacyFloatPoolScheduleRule]

        init(rules: [any LegacyFloatPoolScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyFloatPoolSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyFloatPoolSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyFloatPoolSchedule]) -> [String: [String]] {
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

    static func defaultLegacyFloatPoolScheduleValidator() -> LegacyFloatPoolScheduleValidator {
        return LegacyFloatPoolScheduleValidator(
            rules: [
                LegacyFloatPoolScheduleOwnerIDLengthRule(maxLength: 16),
                LegacyFloatPoolScheduleRefillsRangeRule(min: 32, max: 120),
                LegacyFloatPoolScheduleCodeLengthRule(maxLength: 255),
                LegacyFloatPoolScheduleRequiredSummaryRule(message: "legacy float pool schedule needs an entry"),
                LegacyFloatPoolScheduleApprovedGuardRule(limit: 16),
            ]
        )
    }
}

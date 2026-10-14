import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol schedule must pass. Check returns its problems, or none.
    protocol CareProtocolScheduleRule {
        func check(_ item: CareProtocolSchedule) -> [String]
    }

    final class CareProtocolScheduleBatchSizeRangeRule: CareProtocolScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolScheduleExternalRefLengthRule: CareProtocolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolScheduleAllowedTitleRule: CareProtocolScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class CareProtocolScheduleCodePrefixRule: CareProtocolScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolScheduleBudgetRangeRule: CareProtocolScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolScheduleChannelLengthRule: CareProtocolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol schedule.
    final class CareProtocolScheduleValidator {
        var rules: [any CareProtocolScheduleRule]

        init(rules: [any CareProtocolScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolSchedule]) -> [String: [String]] {
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

    static func defaultCareProtocolScheduleValidator() -> CareProtocolScheduleValidator {
        return CareProtocolScheduleValidator(
            rules: [
                CareProtocolScheduleBatchSizeRangeRule(min: 32, max: 86400),
                CareProtocolScheduleExternalRefLengthRule(maxLength: 3600),
                CareProtocolScheduleAllowedTitleRule(allowed: []),
                CareProtocolScheduleCodePrefixRule(prefix: "X"),
                CareProtocolScheduleBudgetRangeRule(min: 6.3, max: 4740.8),
                CareProtocolScheduleChannelLengthRule(maxLength: 255),
            ]
        )
    }
}

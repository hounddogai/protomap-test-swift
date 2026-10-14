import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled risk score record must pass. Check returns its problems, or none.
    protocol ScheduledRiskScoreRecordRule {
        func check(_ item: ScheduledRiskScoreRecord) -> [String]
    }

    final class ScheduledRiskScoreRecordRegionLengthRule: ScheduledRiskScoreRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRiskScoreRecord) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRiskScoreRecordRetriesRangeRule: ScheduledRiskScoreRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRiskScoreRecord) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRiskScoreRecordRequiredCodeRule: ScheduledRiskScoreRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRiskScoreRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRiskScoreRecordCodePrefixRule: ScheduledRiskScoreRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledRiskScoreRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledRiskScoreRecordVisibleGuardRule: ScheduledRiskScoreRecordRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledRiskScoreRecord) -> [String] {
            if item.visible && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled risk score record.
    final class ScheduledRiskScoreRecordValidator {
        var rules: [any ScheduledRiskScoreRecordRule]

        init(rules: [any ScheduledRiskScoreRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRiskScoreRecord) -> [String] {
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

        func requireValid(_ item: ScheduledRiskScoreRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRiskScoreRecord]) -> [String: [String]] {
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

    static func defaultScheduledRiskScoreRecordValidator() -> ScheduledRiskScoreRecordValidator {
        return ScheduledRiskScoreRecordValidator(
            rules: [
                ScheduledRiskScoreRecordRegionLengthRule(maxLength: 3600),
                ScheduledRiskScoreRecordRetriesRangeRule(min: 16, max: 16),
                ScheduledRiskScoreRecordRequiredCodeRule(message: "scheduled risk score record needs an entry"),
                ScheduledRiskScoreRecordCodePrefixRule(prefix: "OPS"),
                ScheduledRiskScoreRecordVisibleGuardRule(limit: 80),
            ]
        )
    }
}

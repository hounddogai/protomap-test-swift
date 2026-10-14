import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global goal record must pass. Check returns its problems, or none.
    protocol GlobalGoalRecordRule {
        func check(_ item: GlobalGoalRecord) -> [String]
    }

    final class GlobalGoalRecordRequiredTitleRule: GlobalGoalRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalGoalRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalGoalRecordAllowedWardRule: GlobalGoalRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalGoalRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is blocked"]
            }
            return []
        }
    }

    final class GlobalGoalRecordAttemptsRangeRule: GlobalGoalRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalGoalRecord) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalGoalRecordRequiredRegionRule: GlobalGoalRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalGoalRecord) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalGoalRecordWardLengthRule: GlobalGoalRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalGoalRecord) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalGoalRecordCodeLengthRule: GlobalGoalRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalGoalRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global goal record.
    final class GlobalGoalRecordValidator {
        var rules: [any GlobalGoalRecordRule]

        init(rules: [any GlobalGoalRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalGoalRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalGoalRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalGoalRecord]) -> [String: [String]] {
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

    static func defaultGlobalGoalRecordValidator() -> GlobalGoalRecordValidator {
        return GlobalGoalRecordValidator(
            rules: [
                GlobalGoalRecordRequiredTitleRule(message: "global goal record needs an entry"),
                GlobalGoalRecordAllowedWardRule(allowed: []),
                GlobalGoalRecordAttemptsRangeRule(min: 255, max: 1000),
                GlobalGoalRecordRequiredRegionRule(message: "global goal record needs a value"),
                GlobalGoalRecordWardLengthRule(maxLength: 86400),
                GlobalGoalRecordCodeLengthRule(maxLength: 16),
            ]
        )
    }
}

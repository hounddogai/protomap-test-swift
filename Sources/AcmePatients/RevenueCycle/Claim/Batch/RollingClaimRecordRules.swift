import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling claim record must pass. Check returns its problems, or none.
    protocol RollingClaimRecordRule {
        func check(_ item: RollingClaimRecord) -> [String]
    }

    final class RollingClaimRecordRequiredCodeRule: RollingClaimRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClaimRecordVisitMinutesRangeRule: RollingClaimRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClaimRecord) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingClaimRecordRequiredNameRule: RollingClaimRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClaimRecordDescriptionLengthRule: RollingClaimRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingClaimRecord) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling claim record.
    final class RollingClaimRecordValidator {
        var rules: [any RollingClaimRecordRule]

        init(rules: [any RollingClaimRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingClaimRecord) -> [String] {
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

        func requireValid(_ item: RollingClaimRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingClaimRecord]) -> [String: [String]] {
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

    static func defaultRollingClaimRecordValidator() -> RollingClaimRecordValidator {
        return RollingClaimRecordValidator(
            rules: [
                RollingClaimRecordRequiredCodeRule(message: "rolling claim record needs this field"),
                RollingClaimRecordVisitMinutesRangeRule(min: 64, max: 120),
                RollingClaimRecordRequiredNameRule(message: "rolling claim record needs this field"),
                RollingClaimRecordDescriptionLengthRule(maxLength: 64),
            ]
        )
    }
}

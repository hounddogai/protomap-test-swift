import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy statement record must pass. Check returns its problems, or none.
    protocol LegacyStatementRecordRule {
        func check(_ item: LegacyStatementRecord) -> [String]
    }

    final class LegacyStatementRecordUpdatedAtRangeRule: LegacyStatementRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyStatementRecord) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyStatementRecordPhoneLengthRule: LegacyStatementRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStatementRecord) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStatementRecordRequiredExternalRefRule: LegacyStatementRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStatementRecord) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy statement record.
    final class LegacyStatementRecordValidator {
        var rules: [any LegacyStatementRecordRule]

        init(rules: [any LegacyStatementRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyStatementRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyStatementRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyStatementRecord]) -> [String: [String]] {
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

    static func defaultLegacyStatementRecordValidator() -> LegacyStatementRecordValidator {
        return LegacyStatementRecordValidator(
            rules: [
                LegacyStatementRecordUpdatedAtRangeRule(min: 255, max: 86400),
                LegacyStatementRecordPhoneLengthRule(maxLength: 3600),
                LegacyStatementRecordRequiredExternalRefRule(message: "legacy statement record needs an entry"),
            ]
        )
    }
}

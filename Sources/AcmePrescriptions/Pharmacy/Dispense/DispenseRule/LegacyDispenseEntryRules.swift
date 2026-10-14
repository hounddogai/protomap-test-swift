import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy dispense entry must pass. Check returns its problems, or none.
    protocol LegacyDispenseEntryRule {
        func check(_ item: LegacyDispenseEntry) -> [String]
    }

    final class LegacyDispenseEntryAttemptsRangeRule: LegacyDispenseEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyDispenseEntry) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyDispenseEntryEncounterIDLengthRule: LegacyDispenseEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDispenseEntry) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyDispenseEntryCodeLengthRule: LegacyDispenseEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDispenseEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy dispense entry.
    final class LegacyDispenseEntryValidator {
        var rules: [any LegacyDispenseEntryRule]

        init(rules: [any LegacyDispenseEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyDispenseEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyDispenseEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyDispenseEntry]) -> [String: [String]] {
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

    static func defaultLegacyDispenseEntryValidator() -> LegacyDispenseEntryValidator {
        return LegacyDispenseEntryValidator(
            rules: [
                LegacyDispenseEntryAttemptsRangeRule(min: 120, max: 255),
                LegacyDispenseEntryEncounterIDLengthRule(maxLength: 86400),
                LegacyDispenseEntryCodeLengthRule(maxLength: 32),
            ]
        )
    }
}

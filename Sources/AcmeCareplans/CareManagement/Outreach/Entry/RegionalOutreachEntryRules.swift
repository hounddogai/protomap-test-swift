import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional outreach entry must pass. Check returns its problems, or none.
    protocol RegionalOutreachEntryRule {
        func check(_ item: RegionalOutreachEntry) -> [String]
    }

    final class RegionalOutreachEntryRequiredCodeRule: RegionalOutreachEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOutreachEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOutreachEntryRetriesRangeRule: RegionalOutreachEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOutreachEntry) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalOutreachEntryUnitLengthRule: RegionalOutreachEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOutreachEntry) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOutreachEntryRevisionRangeRule: RegionalOutreachEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOutreachEntry) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalOutreachEntryRequiredUnitRule: RegionalOutreachEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOutreachEntry) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional outreach entry.
    final class RegionalOutreachEntryValidator {
        var rules: [any RegionalOutreachEntryRule]

        init(rules: [any RegionalOutreachEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOutreachEntry) -> [String] {
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

        func requireValid(_ item: RegionalOutreachEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOutreachEntry]) -> [String: [String]] {
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

    static func defaultRegionalOutreachEntryValidator() -> RegionalOutreachEntryValidator {
        return RegionalOutreachEntryValidator(
            rules: [
                RegionalOutreachEntryRequiredCodeRule(message: "regional outreach entry needs this field"),
                RegionalOutreachEntryRetriesRangeRule(min: 80, max: 255),
                RegionalOutreachEntryUnitLengthRule(maxLength: 86400),
                RegionalOutreachEntryRevisionRangeRule(min: 255, max: 255),
                RegionalOutreachEntryRequiredUnitRule(message: "regional outreach entry needs an entry"),
            ]
        )
    }
}

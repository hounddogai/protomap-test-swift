import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary outreach entry must pass. Check returns its problems, or none.
    protocol PrimaryOutreachEntryRule {
        func check(_ item: PrimaryOutreachEntry) -> [String]
    }

    final class PrimaryOutreachEntryRequiredWardRule: PrimaryOutreachEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachEntry) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOutreachEntryExpiresAtRangeRule: PrimaryOutreachEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOutreachEntry) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryOutreachEntryTitleLengthRule: PrimaryOutreachEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachEntryBatchSizeRangeRule: PrimaryOutreachEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOutreachEntry) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary outreach entry.
    final class PrimaryOutreachEntryValidator {
        var rules: [any PrimaryOutreachEntryRule]

        init(rules: [any PrimaryOutreachEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOutreachEntry) -> [String] {
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

        func requireValid(_ item: PrimaryOutreachEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOutreachEntry]) -> [String: [String]] {
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

    static func defaultPrimaryOutreachEntryValidator() -> PrimaryOutreachEntryValidator {
        return PrimaryOutreachEntryValidator(
            rules: [
                PrimaryOutreachEntryRequiredWardRule(message: "primary outreach entry needs a value"),
                PrimaryOutreachEntryExpiresAtRangeRule(min: 64, max: 64),
                PrimaryOutreachEntryTitleLengthRule(maxLength: 64),
                PrimaryOutreachEntryBatchSizeRangeRule(min: 64, max: 120),
            ]
        )
    }
}

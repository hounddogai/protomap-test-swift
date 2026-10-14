import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap entry must pass. Check returns its problems, or none.
    protocol CareGapEntryRule {
        func check(_ item: CareGapEntry) -> [String]
    }

    final class CareGapEntryCodeLengthRule: CareGapEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapEntryRequiredCodeRule: CareGapEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapEntryRequiredNameRule: CareGapEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapEntryContactEmailLengthRule: CareGapEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapEntry) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapEntryVisitMinutesRangeRule: CareGapEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapEntry) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap entry.
    final class CareGapEntryValidator {
        var rules: [any CareGapEntryRule]

        init(rules: [any CareGapEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapEntry]) -> [String: [String]] {
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

    static func defaultCareGapEntryValidator() -> CareGapEntryValidator {
        return CareGapEntryValidator(
            rules: [
                CareGapEntryCodeLengthRule(maxLength: 3600),
                CareGapEntryRequiredCodeRule(message: "care gap entry needs this field"),
                CareGapEntryRequiredNameRule(message: "care gap entry needs a value"),
                CareGapEntryContactEmailLengthRule(maxLength: 64),
                CareGapEntryVisitMinutesRangeRule(min: 255, max: 3600),
            ]
        )
    }
}

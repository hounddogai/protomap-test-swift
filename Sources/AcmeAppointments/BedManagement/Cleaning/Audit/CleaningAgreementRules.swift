import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning agreement must pass. Check returns its problems, or none.
    protocol CleaningAgreementRule {
        func check(_ item: CleaningAgreement) -> [String]
    }

    final class CleaningAgreementRequiredNameRule: CleaningAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningAgreementRequiredCodeRule: CleaningAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningAgreementRevisionRangeRule: CleaningAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningAgreement) -> [String] {
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

    final class CleaningAgreementNameLengthRule: CleaningAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning agreement.
    final class CleaningAgreementValidator {
        var rules: [any CleaningAgreementRule]

        init(rules: [any CleaningAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningAgreement) -> [String] {
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

        func requireValid(_ item: CleaningAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningAgreement]) -> [String: [String]] {
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

    static func defaultCleaningAgreementValidator() -> CleaningAgreementValidator {
        return CleaningAgreementValidator(
            rules: [
                CleaningAgreementRequiredNameRule(message: "cleaning agreement needs a value"),
                CleaningAgreementRequiredCodeRule(message: "cleaning agreement needs a value"),
                CleaningAgreementRevisionRangeRule(min: 32, max: 255),
                CleaningAgreementNameLengthRule(maxLength: 1000),
            ]
        )
    }
}

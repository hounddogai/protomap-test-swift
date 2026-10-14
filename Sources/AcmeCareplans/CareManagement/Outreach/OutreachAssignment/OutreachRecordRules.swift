import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach record must pass. Check returns its problems, or none.
    protocol OutreachRecordRule {
        func check(_ item: OutreachRecord) -> [String]
    }

    final class OutreachRecordRequiredNameRule: OutreachRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachRecordPatientRefLengthRule: OutreachRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachRecord) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachRecordNameLengthRule: OutreachRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach record.
    final class OutreachRecordValidator {
        var rules: [any OutreachRecordRule]

        init(rules: [any OutreachRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachRecord) -> [String] {
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

        func requireValid(_ item: OutreachRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachRecord]) -> [String: [String]] {
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

    static func defaultOutreachRecordValidator() -> OutreachRecordValidator {
        return OutreachRecordValidator(
            rules: [
                OutreachRecordRequiredNameRule(message: "outreach record needs an entry"),
                OutreachRecordPatientRefLengthRule(maxLength: 80),
                OutreachRecordNameLengthRule(maxLength: 86400),
            ]
        )
    }
}

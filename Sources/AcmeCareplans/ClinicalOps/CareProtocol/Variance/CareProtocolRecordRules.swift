import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol record must pass. Check returns its problems, or none.
    protocol CareProtocolRecordRule {
        func check(_ item: CareProtocolRecord) -> [String]
    }

    final class CareProtocolRecordPatientRefLengthRule: CareProtocolRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolRecord) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolRecordRequiredPatientRefRule: CareProtocolRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolRecord) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolRecordEndsAtRangeRule: CareProtocolRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolRecord) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol record.
    final class CareProtocolRecordValidator {
        var rules: [any CareProtocolRecordRule]

        init(rules: [any CareProtocolRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolRecord) -> [String] {
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

        func requireValid(_ item: CareProtocolRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolRecord]) -> [String: [String]] {
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

    static func defaultCareProtocolRecordValidator() -> CareProtocolRecordValidator {
        return CareProtocolRecordValidator(
            rules: [
                CareProtocolRecordPatientRefLengthRule(maxLength: 1000),
                CareProtocolRecordRequiredPatientRefRule(message: "care protocol record needs an entry"),
                CareProtocolRecordEndsAtRangeRule(min: 32, max: 86400),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan record must pass. Check returns its problems, or none.
    protocol DischargePlanRecordRule {
        func check(_ item: DischargePlanRecord) -> [String]
    }

    final class DischargePlanRecordMinimumRangeRule: DischargePlanRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanRecord) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanRecordRequiredDiagnosisCodeRule: DischargePlanRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanRecord) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanRecordDiagnosisCodeLengthRule: DischargePlanRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanRecord) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan record.
    final class DischargePlanRecordValidator {
        var rules: [any DischargePlanRecordRule]

        init(rules: [any DischargePlanRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanRecord) -> [String] {
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

        func requireValid(_ item: DischargePlanRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanRecord]) -> [String: [String]] {
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

    static func defaultDischargePlanRecordValidator() -> DischargePlanRecordValidator {
        return DischargePlanRecordValidator(
            rules: [
                DischargePlanRecordMinimumRangeRule(min: 7.2, max: 4837.5),
                DischargePlanRecordRequiredDiagnosisCodeRule(message: "discharge plan record needs a value"),
                DischargePlanRecordDiagnosisCodeLengthRule(maxLength: 64),
            ]
        )
    }
}

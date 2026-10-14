import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime entry must pass. Check returns its problems, or none.
    protocol OvertimeEntryRule {
        func check(_ item: OvertimeEntry) -> [String]
    }

    final class OvertimeEntryNameLengthRule: OvertimeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeEntryRequiredProcedureCodeRule: OvertimeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeEntry) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeEntryRequiredAllergyRule: OvertimeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeEntry) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeEntryRequiredCodeRule: OvertimeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeEntryCodeLengthRule: OvertimeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeEntryAcuityRangeRule: OvertimeEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeEntry) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a overtime entry.
    final class OvertimeEntryValidator {
        var rules: [any OvertimeEntryRule]

        init(rules: [any OvertimeEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeEntry) -> [String] {
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

        func requireValid(_ item: OvertimeEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeEntry]) -> [String: [String]] {
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

    static func defaultOvertimeEntryValidator() -> OvertimeEntryValidator {
        return OvertimeEntryValidator(
            rules: [
                OvertimeEntryNameLengthRule(maxLength: 255),
                OvertimeEntryRequiredProcedureCodeRule(message: "overtime entry needs this field"),
                OvertimeEntryRequiredAllergyRule(message: "overtime entry needs this field"),
                OvertimeEntryRequiredCodeRule(message: "overtime entry needs this field"),
                OvertimeEntryCodeLengthRule(maxLength: 120),
                OvertimeEntryAcuityRangeRule(min: 64, max: 80),
            ]
        )
    }
}

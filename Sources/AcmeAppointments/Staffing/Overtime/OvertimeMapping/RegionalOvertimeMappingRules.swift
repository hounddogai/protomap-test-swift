import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional overtime mapping must pass. Check returns its problems, or none.
    protocol RegionalOvertimeMappingRule {
        func check(_ item: RegionalOvertimeMapping) -> [String]
    }

    final class RegionalOvertimeMappingCopayRangeRule: RegionalOvertimeMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOvertimeMapping) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalOvertimeMappingClinicianIDLengthRule: RegionalOvertimeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimeMapping) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOvertimeMappingNameLengthRule: RegionalOvertimeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimeMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOvertimeMappingProcedureCodeLengthRule: RegionalOvertimeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimeMapping) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOvertimeMappingRequiredCodeRule: RegionalOvertimeMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOvertimeMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional overtime mapping.
    final class RegionalOvertimeMappingValidator {
        var rules: [any RegionalOvertimeMappingRule]

        init(rules: [any RegionalOvertimeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOvertimeMapping) -> [String] {
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

        func requireValid(_ item: RegionalOvertimeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOvertimeMapping]) -> [String: [String]] {
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

    static func defaultRegionalOvertimeMappingValidator() -> RegionalOvertimeMappingValidator {
        return RegionalOvertimeMappingValidator(
            rules: [
                RegionalOvertimeMappingCopayRangeRule(min: 3.7, max: 203.4),
                RegionalOvertimeMappingClinicianIDLengthRule(maxLength: 120),
                RegionalOvertimeMappingNameLengthRule(maxLength: 1000),
                RegionalOvertimeMappingProcedureCodeLengthRule(maxLength: 86400),
                RegionalOvertimeMappingRequiredCodeRule(message: "regional overtime mapping needs an entry"),
            ]
        )
    }
}

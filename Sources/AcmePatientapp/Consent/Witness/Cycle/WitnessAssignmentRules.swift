import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness assignment must pass. Check returns its problems, or none.
    protocol WitnessAssignmentRule {
        func check(_ item: WitnessAssignment) -> [String]
    }

    final class WitnessAssignmentCodePrefixRule: WitnessAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessAssignmentRequiredCodeRule: WitnessAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessAssignmentThresholdRangeRule: WitnessAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessAssignment) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessAssignmentRequiredProcedureCodeRule: WitnessAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessAssignment) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessAssignmentDosageMgRangeRule: WitnessAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessAssignment) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessAssignmentProcedureCodeLengthRule: WitnessAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessAssignment) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness assignment.
    final class WitnessAssignmentValidator {
        var rules: [any WitnessAssignmentRule]

        init(rules: [any WitnessAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessAssignment) -> [String] {
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

        func requireValid(_ item: WitnessAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessAssignment]) -> [String: [String]] {
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

    static func defaultWitnessAssignmentValidator() -> WitnessAssignmentValidator {
        return WitnessAssignmentValidator(
            rules: [
                WitnessAssignmentCodePrefixRule(prefix: "Q"),
                WitnessAssignmentRequiredCodeRule(message: "witness assignment needs this field"),
                WitnessAssignmentThresholdRangeRule(min: 5.7, max: 4563.6),
                WitnessAssignmentRequiredProcedureCodeRule(message: "witness assignment needs an entry"),
                WitnessAssignmentDosageMgRangeRule(min: 8.8, max: 3525.2),
                WitnessAssignmentProcedureCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

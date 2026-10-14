import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan adjustment must pass. Check returns its problems, or none.
    protocol DischargePlanAdjustmentRule {
        func check(_ item: DischargePlanAdjustment) -> [String]
    }

    final class DischargePlanAdjustmentRequiredDiagnosisCodeRule: DischargePlanAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanAdjustment) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanAdjustmentTitleLengthRule: DischargePlanAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanAdjustmentRequiredTitleRule: DischargePlanAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanAdjustmentCodeLengthRule: DischargePlanAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan adjustment.
    final class DischargePlanAdjustmentValidator {
        var rules: [any DischargePlanAdjustmentRule]

        init(rules: [any DischargePlanAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanAdjustment]) -> [String: [String]] {
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

    static func defaultDischargePlanAdjustmentValidator() -> DischargePlanAdjustmentValidator {
        return DischargePlanAdjustmentValidator(
            rules: [
                DischargePlanAdjustmentRequiredDiagnosisCodeRule(message: "discharge plan adjustment needs a value"),
                DischargePlanAdjustmentTitleLengthRule(maxLength: 32),
                DischargePlanAdjustmentRequiredTitleRule(message: "discharge plan adjustment needs this field"),
                DischargePlanAdjustmentCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}

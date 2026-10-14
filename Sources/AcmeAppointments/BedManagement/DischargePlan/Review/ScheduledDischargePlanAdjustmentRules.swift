import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled discharge plan adjustment must pass. Check returns its problems, or none.
    protocol ScheduledDischargePlanAdjustmentRule {
        func check(_ item: ScheduledDischargePlanAdjustment) -> [String]
    }

    final class ScheduledDischargePlanAdjustmentRequiredDiagnosisCodeRule: ScheduledDischargePlanAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDischargePlanAdjustment) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledDischargePlanAdjustmentRequiredContactEmailRule: ScheduledDischargePlanAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDischargePlanAdjustment) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledDischargePlanAdjustmentCodeLengthRule: ScheduledDischargePlanAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDischargePlanAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledDischargePlanAdjustmentContactEmailLengthRule: ScheduledDischargePlanAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDischargePlanAdjustment) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled discharge plan adjustment.
    final class ScheduledDischargePlanAdjustmentValidator {
        var rules: [any ScheduledDischargePlanAdjustmentRule]

        init(rules: [any ScheduledDischargePlanAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledDischargePlanAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledDischargePlanAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledDischargePlanAdjustment]) -> [String: [String]] {
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

    static func defaultScheduledDischargePlanAdjustmentValidator() -> ScheduledDischargePlanAdjustmentValidator {
        return ScheduledDischargePlanAdjustmentValidator(
            rules: [
                ScheduledDischargePlanAdjustmentRequiredDiagnosisCodeRule(
                    message: "scheduled discharge plan adjustment needs an entry"
                ),
                ScheduledDischargePlanAdjustmentRequiredContactEmailRule(
                    message: "scheduled discharge plan adjustment needs a value"
                ),
                ScheduledDischargePlanAdjustmentCodeLengthRule(maxLength: 3600),
                ScheduledDischargePlanAdjustmentContactEmailLengthRule(maxLength: 16),
            ]
        )
    }
}

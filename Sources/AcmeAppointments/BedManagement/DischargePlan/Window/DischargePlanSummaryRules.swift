import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan summary must pass. Check returns its problems, or none.
    protocol DischargePlanSummaryRule {
        func check(_ item: DischargePlanSummary) -> [String]
    }

    final class DischargePlanSummaryRequiredDescriptionRule: DischargePlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanSummary) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanSummaryClinicianIDLengthRule: DischargePlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanSummary) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanSummaryAllowedClinicianIDRule: DischargePlanSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is blocked"]
            }
            return []
        }
    }

    final class DischargePlanSummaryLabelLengthRule: DischargePlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanSummaryRequiredCodeRule: DischargePlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan summary.
    final class DischargePlanSummaryValidator {
        var rules: [any DischargePlanSummaryRule]

        init(rules: [any DischargePlanSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanSummary) -> [String] {
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

        func requireValid(_ item: DischargePlanSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanSummary]) -> [String: [String]] {
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

    static func defaultDischargePlanSummaryValidator() -> DischargePlanSummaryValidator {
        return DischargePlanSummaryValidator(
            rules: [
                DischargePlanSummaryRequiredDescriptionRule(message: "discharge plan summary needs an entry"),
                DischargePlanSummaryClinicianIDLengthRule(maxLength: 32),
                DischargePlanSummaryAllowedClinicianIDRule(allowed: ["strict", "seasonal"]),
                DischargePlanSummaryLabelLengthRule(maxLength: 3600),
                DischargePlanSummaryRequiredCodeRule(message: "discharge plan summary needs a value"),
            ]
        )
    }
}

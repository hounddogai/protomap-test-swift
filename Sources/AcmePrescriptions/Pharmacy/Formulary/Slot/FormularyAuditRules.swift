import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary audit must pass. Check returns its problems, or none.
    protocol FormularyAuditRule {
        func check(_ item: FormularyAudit) -> [String]
    }

    final class FormularyAuditPatientRefLengthRule: FormularyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyAudit) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyAuditLabelLengthRule: FormularyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyAudit) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyAuditRequiredPatientRefRule: FormularyAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyAudit) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyAuditCodeLengthRule: FormularyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyAuditRequiredCodeRule: FormularyAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyAuditRequiredCountryRule: FormularyAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyAudit) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a formulary audit.
    final class FormularyAuditValidator {
        var rules: [any FormularyAuditRule]

        init(rules: [any FormularyAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyAudit]) -> [String: [String]] {
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

    static func defaultFormularyAuditValidator() -> FormularyAuditValidator {
        return FormularyAuditValidator(
            rules: [
                FormularyAuditPatientRefLengthRule(maxLength: 64),
                FormularyAuditLabelLengthRule(maxLength: 64),
                FormularyAuditRequiredPatientRefRule(message: "formulary audit needs this field"),
                FormularyAuditCodeLengthRule(maxLength: 80),
                FormularyAuditRequiredCodeRule(message: "formulary audit needs this field"),
                FormularyAuditRequiredCountryRule(message: "formulary audit needs this field"),
            ]
        )
    }
}

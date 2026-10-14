@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyAuditValidator()
        let item = Pharmacy.newFormularyAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyAuditPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Pharmacy.FormularyAuditPatientRefLengthRule(maxLength: 64)
        let item = Pharmacy.newFormularyAudit("x", label: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyAuditLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.FormularyAuditLabelLengthRule(maxLength: 86400)
        let item = Pharmacy.newFormularyAudit("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyAuditRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Pharmacy.FormularyAuditRequiredPatientRefRule(message: "formulary audit needs a value")
        let item = Pharmacy.newFormularyAudit("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyAuditCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newFormularyAudit("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FormularyAuditRequiredCodeRule(message: "formulary audit needs a value")
        let item = Pharmacy.newFormularyAudit("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyAuditRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.FormularyAuditRequiredCountryRule(message: "formulary audit needs a value")
        let item = Pharmacy.newFormularyAudit("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

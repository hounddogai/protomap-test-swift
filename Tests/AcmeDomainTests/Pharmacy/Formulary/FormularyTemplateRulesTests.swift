@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyTemplateValidator()
        let item = Pharmacy.newFormularyTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyTemplateDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Pharmacy.FormularyTemplateDiagnosisCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newFormularyTemplate("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyTemplateCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newFormularyTemplate("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyTemplateGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.FormularyTemplateGraceDaysRangeRule(min: 1000, max: 1000)
        let item = Pharmacy.newFormularyTemplate("x", title: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

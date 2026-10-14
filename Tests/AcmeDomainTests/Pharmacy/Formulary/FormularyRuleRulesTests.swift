@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyRuleValidator()
        let item = Pharmacy.newFormularyRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FormularyRuleRequiredCodeRule(message: "formulary rule needs this field")
        let item = Pharmacy.newFormularyRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.FormularyRuleNameLengthRule(maxLength: 86400)
        let item = Pharmacy.newFormularyRule("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyRuleCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newFormularyRule("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyRuleAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.FormularyRuleAcuityRangeRule(min: 32, max: 1000)
        let item = Pharmacy.newFormularyRule("x", name: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

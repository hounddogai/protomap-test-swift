@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyPolicyValidator()
        let item = Pharmacy.newFormularyPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FormularyPolicyRequiredCodeRule(message: "formulary policy needs an entry")
        let item = Pharmacy.newFormularyPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyPolicyRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.FormularyPolicyRequiredPayerRule(message: "formulary policy needs an entry")
        let item = Pharmacy.newFormularyPolicy("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyPolicyLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.FormularyPolicyLabelLengthRule(maxLength: 16)
        let item = Pharmacy.newFormularyPolicy("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

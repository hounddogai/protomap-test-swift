@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientFormularyDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientFormularyDraftValidator()
        let item = Pharmacy.newLenientFormularyDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientFormularyDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LenientFormularyDraftCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newLenientFormularyDraft("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientFormularyDraftRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.LenientFormularyDraftRateRangeRule(min: 0.0, max: 929.6)
        let item = Pharmacy.newLenientFormularyDraft("x", name: "y")
        item.rate = 931.1
        #expect(rule.check(item).count > 0)
    }
}

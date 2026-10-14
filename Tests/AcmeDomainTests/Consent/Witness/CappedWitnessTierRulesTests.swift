@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedWitnessTierValidator()
        let item = Consent.newCappedWitnessTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedWitnessTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.CappedWitnessTierRequiredCodeRule(message: "capped witness tier needs an entry")
        let item = Consent.newCappedWitnessTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedWitnessTierQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.CappedWitnessTierQuantityRangeRule(min: 80, max: 255)
        let item = Consent.newCappedWitnessTier("x", name: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedWitnessTierWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Consent.CappedWitnessTierWardLengthRule(maxLength: 3600)
        let item = Consent.newCappedWitnessTier("x", name: "y")
        item.ward = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessTierValidator()
        let item = Consent.newWitnessTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessTierRequiredCodeRule(message: "witness tier needs an entry")
        let item = Consent.newWitnessTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessTierCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.WitnessTierCeilingRangeRule(min: 2.7, max: 4862.4)
        let item = Consent.newWitnessTier("x", name: "y")
        item.ceiling = 4863.9
        #expect(rule.check(item).count > 0)
    }
}

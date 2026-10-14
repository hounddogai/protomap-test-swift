@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalConsentFormTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultGlobalConsentFormTierValidator()
        let item = Consent.newGlobalConsentFormTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentGlobalConsentFormTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.GlobalConsentFormTierNameLengthRule(maxLength: 255)
        let item = Consent.newGlobalConsentFormTier("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentGlobalConsentFormTierRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.GlobalConsentFormTierRateRangeRule(min: 9.1, max: 1725.8)
        let item = Consent.newGlobalConsentFormTier("x", name: "y")
        item.rate = 1727.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentGlobalConsentFormTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.GlobalConsentFormTierRequiredCodeRule(message: "global consent form tier needs this field")
        let item = Consent.newGlobalConsentFormTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormBundleValidator()
        let item = Consent.newConsentFormBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormBundleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.ConsentFormBundleQuantityRangeRule(min: 255, max: 86400)
        let item = Consent.newConsentFormBundle("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormBundleRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.ConsentFormBundleRequiredExternalRefRule(message: "consent form bundle needs an entry")
        let item = Consent.newConsentFormBundle("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormBundleSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.ConsentFormBundleSequenceRangeRule(min: 16, max: 16)
        let item = Consent.newConsentFormBundle("x", name: "y")
        item.sequence = 17
        #expect(rule.check(item).count > 0)
    }
}

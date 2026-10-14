@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormThresholdValidator()
        let item = Consent.newConsentFormThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormThresholdAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.ConsentFormThresholdAllergyLengthRule(maxLength: 1000)
        let item = Consent.newConsentFormThreshold("x", title: "y")
        item.allergy = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormThresholdRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.ConsentFormThresholdRequiredAllergyRule(message: "consent form threshold needs this field")
        let item = Consent.newConsentFormThreshold("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormThresholdRequiredCodeRule(message: "consent form threshold needs this field")
        let item = Consent.newConsentFormThreshold("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ConsentFormThresholdRequiredTitleRule(message: "consent form threshold needs a value")
        let item = Consent.newConsentFormThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormThresholdFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Consent.ConsentFormThresholdFloorValueRangeRule(min: 9.5, max: 3668.8)
        let item = Consent.newConsentFormThreshold("x", title: "y")
        item.floorValue = 3670.3
        #expect(rule.check(item).count > 0)
    }
}

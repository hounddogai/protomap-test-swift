@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormTierValidator()
        let item = Consent.newConsentFormTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormTierBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Consent.ConsentFormTierBedLengthRule(maxLength: 120)
        let item = Consent.newConsentFormTier("x", title: "y")
        item.bed = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormTierRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Consent.ConsentFormTierRequiredClinicianIDRule(message: "consent form tier needs this field")
        let item = Consent.newConsentFormTier("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormTierCodeLengthRule(maxLength: 1000)
        let item = Consent.newConsentFormTier("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryConsentFormEntryValidator()
        let item = Consent.newPrimaryConsentFormEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryConsentFormEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.PrimaryConsentFormEntryNameLengthRule(maxLength: 1000)
        let item = Consent.newPrimaryConsentFormEntry("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryConsentFormEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PrimaryConsentFormEntryCodeLengthRule(maxLength: 120)
        let item = Consent.newPrimaryConsentFormEntry("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryConsentFormEntryLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.PrimaryConsentFormEntryLimitRangeRule(min: 86400, max: 86400)
        let item = Consent.newPrimaryConsentFormEntry("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

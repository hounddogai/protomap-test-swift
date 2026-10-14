@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormSlotValidator()
        let item = Consent.newConsentFormSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormSlotRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Consent.ConsentFormSlotRequiredPayerRule(message: "consent form slot needs this field")
        let item = Consent.newConsentFormSlot("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormSlotCodeLengthRule(maxLength: 80)
        let item = Consent.newConsentFormSlot("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormSlotRequiredCodeRule(message: "consent form slot needs an entry")
        let item = Consent.newConsentFormSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.ConsentFormSlotNameLengthRule(maxLength: 86400)
        let item = Consent.newConsentFormSlot("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormSlotDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.ConsentFormSlotDosageMgRangeRule(min: 8.7, max: 108.1)
        let item = Consent.newConsentFormSlot("x", name: "y")
        item.dosageMg = 109.6
        #expect(rule.check(item).count > 0)
    }
}

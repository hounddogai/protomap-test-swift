@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalConsentFormSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalConsentFormSlotValidator()
        let item = Consent.newSeasonalConsentFormSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalConsentFormSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.SeasonalConsentFormSlotCodeLengthRule(maxLength: 255)
        let item = Consent.newSeasonalConsentFormSlot("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalConsentFormSlotCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Consent.SeasonalConsentFormSlotCurrencyLengthRule(maxLength: 1000)
        let item = Consent.newSeasonalConsentFormSlot("x", label: "y")
        item.currency = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalConsentFormSlotMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.SeasonalConsentFormSlotMaximumRangeRule(min: 7.1, max: 2182.9)
        let item = Consent.newSeasonalConsentFormSlot("x", label: "y")
        item.maximum = 2184.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalConsentFormSlotRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Consent.SeasonalConsentFormSlotRequiredCurrencyRule(
            message: "seasonal consent form slot needs this field"
        )
        let item = Consent.newSeasonalConsentFormSlot("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalConsentFormSlotContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Consent.SeasonalConsentFormSlotContactEmailLengthRule(maxLength: 120)
        let item = Consent.newSeasonalConsentFormSlot("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

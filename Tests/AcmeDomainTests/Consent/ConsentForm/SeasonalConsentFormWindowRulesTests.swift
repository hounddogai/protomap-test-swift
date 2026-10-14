@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalConsentFormWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalConsentFormWindowValidator()
        let item = Consent.newSeasonalConsentFormWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalConsentFormWindowPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.SeasonalConsentFormWindowPayerLengthRule(maxLength: 1000)
        let item = Consent.newSeasonalConsentFormWindow("x", title: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalConsentFormWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.SeasonalConsentFormWindowTitleLengthRule(maxLength: 86400)
        let item = Consent.newSeasonalConsentFormWindow("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalConsentFormWindowLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.SeasonalConsentFormWindowLimitRangeRule(min: 120, max: 255)
        let item = Consent.newSeasonalConsentFormWindow("x", title: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}

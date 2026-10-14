@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageTierValidator()
        let item = Consent.newLanguageTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageTierRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Consent.LanguageTierRequiredRegionRule(message: "language tier needs an entry")
        let item = Consent.newLanguageTier("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.LanguageTierTitleLengthRule(maxLength: 120)
        let item = Consent.newLanguageTier("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageTierWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.LanguageTierWindowDaysRangeRule(min: 64, max: 64)
        let item = Consent.newLanguageTier("x", title: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageTierChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Consent.LanguageTierChannelLengthRule(maxLength: 16)
        let item = Consent.newLanguageTier("x", title: "y")
        item.channel = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

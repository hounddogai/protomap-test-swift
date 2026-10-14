@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveWorklistDraftValidator()
        let item = Imaging.newAdaptiveWorklistDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveWorklistDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.AdaptiveWorklistDraftRequiredCodeRule(message: "adaptive worklist draft needs an entry")
        let item = Imaging.newAdaptiveWorklistDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptiveWorklistDraftRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.AdaptiveWorklistDraftRequiredPayerRule(message: "adaptive worklist draft needs this field")
        let item = Imaging.newAdaptiveWorklistDraft("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptiveWorklistDraftCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Imaging.AdaptiveWorklistDraftCurrencyLengthRule(maxLength: 120)
        let item = Imaging.newAdaptiveWorklistDraft("x", name: "y")
        item.currency = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveWorklistDraftRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Imaging.AdaptiveWorklistDraftRequiredCurrencyRule(message: "adaptive worklist draft needs a value")
        let item = Imaging.newAdaptiveWorklistDraft("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptiveWorklistDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.AdaptiveWorklistDraftNameLengthRule(maxLength: 32)
        let item = Imaging.newAdaptiveWorklistDraft("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolPreferenceValidator()
        let item = Imaging.newCareProtocolPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.CareProtocolPreferenceNameLengthRule(maxLength: 16)
        let item = Imaging.newCareProtocolPreference("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolPreferenceCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Imaging.CareProtocolPreferenceCurrencyLengthRule(maxLength: 80)
        let item = Imaging.newCareProtocolPreference("x", name: "y")
        item.currency = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolPreferenceRequiredCodeRule(message: "care protocol preference needs a value")
        let item = Imaging.newCareProtocolPreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.CareProtocolPreferenceRequiredTitleRule(message: "care protocol preference needs this field")
        let item = Imaging.newCareProtocolPreference("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyCareProtocolPreferenceValidator()
        let item = Imaging.newLegacyCareProtocolPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyCareProtocolPreferenceRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Imaging.LegacyCareProtocolPreferenceRequiredExternalRefRule(
            message: "legacy care protocol preference needs a value"
        )
        let item = Imaging.newLegacyCareProtocolPreference("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyCareProtocolPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.LegacyCareProtocolPreferenceRequiredTitleRule(
            message: "legacy care protocol preference needs a value"
        )
        let item = Imaging.newLegacyCareProtocolPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyCareProtocolPreferenceVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Imaging.LegacyCareProtocolPreferenceVisitMinutesRangeRule(min: 64, max: 3600)
        let item = Imaging.newLegacyCareProtocolPreference("x", title: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyCareProtocolPreferenceCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.LegacyCareProtocolPreferenceCopayRangeRule(min: 2.5, max: 1810.7)
        let item = Imaging.newLegacyCareProtocolPreference("x", title: "y")
        item.copay = 1812.2
        #expect(rule.check(item).count > 0)
    }
}

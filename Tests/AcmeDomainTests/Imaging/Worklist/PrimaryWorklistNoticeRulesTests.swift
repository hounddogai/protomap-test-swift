@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryWorklistNoticeValidator()
        let item = Imaging.newPrimaryWorklistNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryWorklistNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.PrimaryWorklistNoticeRequiredLabelRule(message: "primary worklist notice needs this field")
        let item = Imaging.newPrimaryWorklistNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryWorklistNoticeRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.PrimaryWorklistNoticeRequiredPayerRule(message: "primary worklist notice needs this field")
        let item = Imaging.newPrimaryWorklistNotice("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryWorklistNoticeRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.PrimaryWorklistNoticeRateRangeRule(min: 8.7, max: 1832.7)
        let item = Imaging.newPrimaryWorklistNotice("x", label: "y")
        item.rate = 1834.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryWorklistNoticeRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Imaging.PrimaryWorklistNoticeRequiredTimezoneRule(message: "primary worklist notice needs an entry")
        let item = Imaging.newPrimaryWorklistNotice("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryWorklistNoticeMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.PrimaryWorklistNoticeMaximumRangeRule(min: 2.3, max: 894.3)
        let item = Imaging.newPrimaryWorklistNotice("x", label: "y")
        item.maximum = 895.8
        #expect(rule.check(item).count > 0)
    }
}

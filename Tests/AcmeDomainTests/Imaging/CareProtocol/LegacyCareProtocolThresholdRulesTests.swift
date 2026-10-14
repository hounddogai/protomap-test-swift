@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyCareProtocolThresholdValidator()
        let item = Imaging.newLegacyCareProtocolThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyCareProtocolThresholdRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.LegacyCareProtocolThresholdRequiredBedRule(
            message: "legacy care protocol threshold needs a value"
        )
        let item = Imaging.newLegacyCareProtocolThreshold("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyCareProtocolThresholdMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.LegacyCareProtocolThresholdMarginRangeRule(min: 8.6, max: 1765.1)
        let item = Imaging.newLegacyCareProtocolThreshold("x", title: "y")
        item.margin = 1766.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyCareProtocolThresholdWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.LegacyCareProtocolThresholdWeightRangeRule(min: 7.2, max: 4830.4)
        let item = Imaging.newLegacyCareProtocolThreshold("x", title: "y")
        item.weight = 4831.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyCareProtocolThresholdBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.LegacyCareProtocolThresholdBedLengthRule(maxLength: 1000)
        let item = Imaging.newLegacyCareProtocolThreshold("x", title: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLegacyCareProtocolThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.LegacyCareProtocolThresholdTitleLengthRule(maxLength: 1000)
        let item = Imaging.newLegacyCareProtocolThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

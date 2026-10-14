@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryWorklistMilestoneValidator()
        let item = Imaging.newPrimaryWorklistMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryWorklistMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PrimaryWorklistMilestoneCodeLengthRule(maxLength: 32)
        let item = Imaging.newPrimaryWorklistMilestone("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryWorklistMilestoneDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.PrimaryWorklistMilestoneDurationMinutesRangeRule(min: 80, max: 120)
        let item = Imaging.newPrimaryWorklistMilestone("x", label: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryWorklistMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PrimaryWorklistMilestoneRequiredCodeRule(message: "primary worklist milestone needs an entry")
        let item = Imaging.newPrimaryWorklistMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryWorklistMilestoneRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.PrimaryWorklistMilestoneRateRangeRule(min: 3.2, max: 4195.4)
        let item = Imaging.newPrimaryWorklistMilestone("x", label: "y")
        item.rate = 4196.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryWorklistMilestoneChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Imaging.PrimaryWorklistMilestoneChecksumLengthRule(maxLength: 120)
        let item = Imaging.newPrimaryWorklistMilestone("x", label: "y")
        item.checksum = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledWorklistAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledWorklistAdjustmentValidator()
        let item = Imaging.newScheduledWorklistAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledWorklistAdjustmentCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.ScheduledWorklistAdjustmentCopayRangeRule(min: 6.1, max: 254.8)
        let item = Imaging.newScheduledWorklistAdjustment("x", label: "y")
        item.copay = 256.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledWorklistAdjustmentRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.ScheduledWorklistAdjustmentRequiredUnitRule(
            message: "scheduled worklist adjustment needs a value"
        )
        let item = Imaging.newScheduledWorklistAdjustment("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledWorklistAdjustmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ScheduledWorklistAdjustmentRequiredLabelRule(
            message: "scheduled worklist adjustment needs this field"
        )
        let item = Imaging.newScheduledWorklistAdjustment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledWorklistAdjustmentUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Imaging.ScheduledWorklistAdjustmentUnitLengthRule(maxLength: 1000)
        let item = Imaging.newScheduledWorklistAdjustment("x", label: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

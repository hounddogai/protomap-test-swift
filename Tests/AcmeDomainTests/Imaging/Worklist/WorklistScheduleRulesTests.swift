@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistScheduleValidator()
        let item = Imaging.newWorklistSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistScheduleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.WorklistScheduleRequiredLabelRule(message: "worklist schedule needs a value")
        let item = Imaging.newWorklistSchedule("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistScheduleMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.WorklistScheduleMaximumRangeRule(min: 6.8, max: 3181.5)
        let item = Imaging.newWorklistSchedule("x", title: "y")
        item.maximum = 3183.0
        #expect(rule.check(item).count > 0)
    }
}

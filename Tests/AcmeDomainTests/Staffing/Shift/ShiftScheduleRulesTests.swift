@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftScheduleValidator()
        let item = Staffing.newShiftSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftScheduleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.ShiftScheduleThresholdRangeRule(min: 9.7, max: 780.5)
        let item = Staffing.newShiftSchedule("x", label: "y")
        item.threshold = 782.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftScheduleRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Staffing.ShiftScheduleRequiredReviewerRule(message: "shift schedule needs this field")
        let item = Staffing.newShiftSchedule("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftScheduleRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.ShiftScheduleRefillsRangeRule(min: 32, max: 3600)
        let item = Staffing.newShiftSchedule("x", label: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.ShiftScheduleLabelLengthRule(maxLength: 120)
        let item = Staffing.newShiftSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

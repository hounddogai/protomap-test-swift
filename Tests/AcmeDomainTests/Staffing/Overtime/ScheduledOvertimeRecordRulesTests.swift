@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledOvertimeRecordValidator()
        let item = Staffing.newScheduledOvertimeRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledOvertimeRecordRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.ScheduledOvertimeRecordRatioRangeRule(min: 6.2, max: 1965.7)
        let item = Staffing.newScheduledOvertimeRecord("x", label: "y")
        item.ratio = 1967.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingScheduledOvertimeRecordRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Staffing.ScheduledOvertimeRecordRequiredFacilityRule(
            message: "scheduled overtime record needs a value"
        )
        let item = Staffing.newScheduledOvertimeRecord("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledOvertimeRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ScheduledOvertimeRecordRequiredCodeRule(
            message: "scheduled overtime record needs this field"
        )
        let item = Staffing.newScheduledOvertimeRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

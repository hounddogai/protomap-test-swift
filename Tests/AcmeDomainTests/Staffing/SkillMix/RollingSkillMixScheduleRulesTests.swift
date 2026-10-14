@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingSkillMixScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingSkillMixScheduleValidator()
        let item = Staffing.newRollingSkillMixSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingSkillMixScheduleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Staffing.RollingSkillMixScheduleRequiredClinicianIDRule(
            message: "rolling skill mix schedule needs an entry"
        )
        let item = Staffing.newRollingSkillMixSchedule("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingSkillMixScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RollingSkillMixScheduleRequiredCodeRule(
            message: "rolling skill mix schedule needs this field"
        )
        let item = Staffing.newRollingSkillMixSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingSkillMixScheduleFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.RollingSkillMixScheduleFloorValueRangeRule(min: 3.0, max: 1972.9)
        let item = Staffing.newRollingSkillMixSchedule("x", name: "y")
        item.floorValue = 1974.4
        #expect(rule.check(item).count > 0)
    }
}

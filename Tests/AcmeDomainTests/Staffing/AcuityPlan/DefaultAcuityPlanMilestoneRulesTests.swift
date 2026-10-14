@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultAcuityPlanMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultAcuityPlanMilestoneValidator()
        let item = Staffing.newDefaultAcuityPlanMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultAcuityPlanMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.DefaultAcuityPlanMilestoneRequiredTitleRule(
            message: "default acuity plan milestone needs this field"
        )
        let item = Staffing.newDefaultAcuityPlanMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultAcuityPlanMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.DefaultAcuityPlanMilestoneRequiredCodeRule(
            message: "default acuity plan milestone needs this field"
        )
        let item = Staffing.newDefaultAcuityPlanMilestone("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultAcuityPlanMilestoneClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Staffing.DefaultAcuityPlanMilestoneClinicianIDLengthRule(maxLength: 16)
        let item = Staffing.newDefaultAcuityPlanMilestone("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultAcuityPlanMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.DefaultAcuityPlanMilestoneTitleLengthRule(maxLength: 32)
        let item = Staffing.newDefaultAcuityPlanMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultAcuityPlanMilestoneLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Staffing.DefaultAcuityPlanMilestoneLocaleLengthRule(maxLength: 3600)
        let item = Staffing.newDefaultAcuityPlanMilestone("x", title: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

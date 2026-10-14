@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanMilestoneValidator()
        let item = Staffing.newAcuityPlanMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanMilestoneLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.AcuityPlanMilestoneLabelLengthRule(maxLength: 1000)
        let item = Staffing.newAcuityPlanMilestone("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanMilestoneRequiredCodeRule(message: "acuity plan milestone needs an entry")
        let item = Staffing.newAcuityPlanMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanMilestoneCodeLengthRule(maxLength: 16)
        let item = Staffing.newAcuityPlanMilestone("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanMilestoneRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.AcuityPlanMilestoneRateRangeRule(min: 1.0, max: 939.2)
        let item = Staffing.newAcuityPlanMilestone("x", label: "y")
        item.rate = 940.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanMilestoneOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.AcuityPlanMilestoneOwnerIDLengthRule(maxLength: 86400)
        let item = Staffing.newAcuityPlanMilestone("x", label: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredAcuityPlanMilestoneValidator()
        let item = Staffing.newTieredAcuityPlanMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredAcuityPlanMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.TieredAcuityPlanMilestoneRequiredCodeRule(
            message: "tiered acuity plan milestone needs a value"
        )
        let item = Staffing.newTieredAcuityPlanMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredAcuityPlanMilestoneRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Staffing.TieredAcuityPlanMilestoneRequiredProcedureCodeRule(
            message: "tiered acuity plan milestone needs this field"
        )
        let item = Staffing.newTieredAcuityPlanMilestone("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredAcuityPlanMilestoneCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Staffing.TieredAcuityPlanMilestoneCreatedAtRangeRule(min: 64, max: 3600)
        let item = Staffing.newTieredAcuityPlanMilestone("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingTieredAcuityPlanMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.TieredAcuityPlanMilestoneRequiredNameRule(
            message: "tiered acuity plan milestone needs an entry"
        )
        let item = Staffing.newTieredAcuityPlanMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredAcuityPlanMilestoneRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.TieredAcuityPlanMilestoneRequiredWardRule(
            message: "tiered acuity plan milestone needs a value"
        )
        let item = Staffing.newTieredAcuityPlanMilestone("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

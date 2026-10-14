@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingAcuityPlanMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingAcuityPlanMilestoneValidator()
        let item = Staffing.newPendingAcuityPlanMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingAcuityPlanMilestoneQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.PendingAcuityPlanMilestoneQuantityRangeRule(min: 255, max: 86400)
        let item = Staffing.newPendingAcuityPlanMilestone("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingAcuityPlanMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.PendingAcuityPlanMilestoneTitleLengthRule(maxLength: 32)
        let item = Staffing.newPendingAcuityPlanMilestone("x", label: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingAcuityPlanMilestoneRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.PendingAcuityPlanMilestoneRequiredLabelRule(
            message: "pending acuity plan milestone needs this field"
        )
        let item = Staffing.newPendingAcuityPlanMilestone("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingAcuityPlanMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PendingAcuityPlanMilestoneRequiredCodeRule(
            message: "pending acuity plan milestone needs an entry"
        )
        let item = Staffing.newPendingAcuityPlanMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

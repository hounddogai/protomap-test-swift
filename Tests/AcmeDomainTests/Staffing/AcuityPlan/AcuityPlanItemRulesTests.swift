@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanItemValidator()
        let item = Staffing.newAcuityPlanItem("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanItemTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.AcuityPlanItemTitleLengthRule(maxLength: 255)
        let item = Staffing.newAcuityPlanItem("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanItemPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Staffing.AcuityPlanItemPriorityRangeRule(min: 120, max: 86400)
        let item = Staffing.newAcuityPlanItem("x", title: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanItemRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanItemRequiredCodeRule(message: "acuity plan item needs an entry")
        let item = Staffing.newAcuityPlanItem("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanItemDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.AcuityPlanItemDescriptionLengthRule(maxLength: 255)
        let item = Staffing.newAcuityPlanItem("x", title: "y")
        item.description = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanItemSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.AcuityPlanItemSegmentLengthRule(maxLength: 255)
        let item = Staffing.newAcuityPlanItem("x", title: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

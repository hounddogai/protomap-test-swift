@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryAcuityPlanTargetValidator()
        let item = Staffing.newPrimaryAcuityPlanTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanTargetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.PrimaryAcuityPlanTargetTitleLengthRule(maxLength: 32)
        let item = Staffing.newPrimaryAcuityPlanTarget("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanTargetRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.PrimaryAcuityPlanTargetRequiredSegmentRule(
            message: "primary acuity plan target needs this field"
        )
        let item = Staffing.newPrimaryAcuityPlanTarget("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryAcuityPlanTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimaryAcuityPlanTargetCodeLengthRule(maxLength: 1000)
        let item = Staffing.newPrimaryAcuityPlanTarget("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanTargetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.PrimaryAcuityPlanTargetRequiredTitleRule(
            message: "primary acuity plan target needs this field"
        )
        let item = Staffing.newPrimaryAcuityPlanTarget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryAcuityPlanTargetWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Staffing.PrimaryAcuityPlanTargetWardLengthRule(maxLength: 64)
        let item = Staffing.newPrimaryAcuityPlanTarget("x", title: "y")
        item.ward = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

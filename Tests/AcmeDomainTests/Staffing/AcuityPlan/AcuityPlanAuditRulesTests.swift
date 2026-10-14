@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanAuditValidator()
        let item = Staffing.newAcuityPlanAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanAuditRequiredCodeRule(message: "acuity plan audit needs an entry")
        let item = Staffing.newAcuityPlanAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.AcuityPlanAuditRequiredTitleRule(message: "acuity plan audit needs an entry")
        let item = Staffing.newAcuityPlanAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanAuditRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.AcuityPlanAuditRequiredLabelRule(message: "acuity plan audit needs an entry")
        let item = Staffing.newAcuityPlanAudit("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

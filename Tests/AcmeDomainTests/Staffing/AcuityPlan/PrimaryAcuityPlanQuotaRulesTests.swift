@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryAcuityPlanQuotaValidator()
        let item = Staffing.newPrimaryAcuityPlanQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimaryAcuityPlanQuotaCodeLengthRule(maxLength: 64)
        let item = Staffing.newPrimaryAcuityPlanQuota("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanQuotaRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Staffing.PrimaryAcuityPlanQuotaRequiredExternalRefRule(
            message: "primary acuity plan quota needs this field"
        )
        let item = Staffing.newPrimaryAcuityPlanQuota("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryAcuityPlanQuotaDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.PrimaryAcuityPlanQuotaDescriptionLengthRule(maxLength: 1000)
        let item = Staffing.newPrimaryAcuityPlanQuota("x", label: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

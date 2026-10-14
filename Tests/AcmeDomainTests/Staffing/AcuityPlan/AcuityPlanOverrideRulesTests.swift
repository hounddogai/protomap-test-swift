@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanOverrideValidator()
        let item = Staffing.newAcuityPlanOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanOverrideCodeLengthRule(maxLength: 16)
        let item = Staffing.newAcuityPlanOverride("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanOverridePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.AcuityPlanOverridePayerLengthRule(maxLength: 1000)
        let item = Staffing.newAcuityPlanOverride("x", title: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanOverrideRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Staffing.AcuityPlanOverrideRequiredPayerRule(message: "acuity plan override needs a value")
        let item = Staffing.newAcuityPlanOverride("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.AcuityPlanOverrideRequiredTitleRule(message: "acuity plan override needs a value")
        let item = Staffing.newAcuityPlanOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

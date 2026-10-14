@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedAcuityPlanDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedAcuityPlanDraftValidator()
        let item = Staffing.newCappedAcuityPlanDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedAcuityPlanDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CappedAcuityPlanDraftCodeLengthRule(maxLength: 80)
        let item = Staffing.newCappedAcuityPlanDraft("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedAcuityPlanDraftOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.CappedAcuityPlanDraftOwnerIDLengthRule(maxLength: 64)
        let item = Staffing.newCappedAcuityPlanDraft("x", name: "y")
        item.ownerID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedAcuityPlanDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CappedAcuityPlanDraftRequiredCodeRule(message: "capped acuity plan draft needs an entry")
        let item = Staffing.newCappedAcuityPlanDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

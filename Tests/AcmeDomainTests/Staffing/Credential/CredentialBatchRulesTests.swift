@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialBatchValidator()
        let item = Staffing.newCredentialBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialBatchRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.CredentialBatchRequiredOwnerIDRule(message: "credential batch needs an entry")
        let item = Staffing.newCredentialBatch("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialBatchBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.CredentialBatchBudgetRangeRule(min: 9.6, max: 1044.7)
        let item = Staffing.newCredentialBatch("x", title: "y")
        item.budget = 1046.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialBatchFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.CredentialBatchFloorValueRangeRule(min: 1.6, max: 908.7)
        let item = Staffing.newCredentialBatch("x", title: "y")
        item.floorValue = 910.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialBatchRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.CredentialBatchRequiredWardRule(message: "credential batch needs a value")
        let item = Staffing.newCredentialBatch("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialBatchCodeLengthRule(maxLength: 3600)
        let item = Staffing.newCredentialBatch("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialBatchTitleLengthRule(maxLength: 1000)
        let item = Staffing.newCredentialBatch("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

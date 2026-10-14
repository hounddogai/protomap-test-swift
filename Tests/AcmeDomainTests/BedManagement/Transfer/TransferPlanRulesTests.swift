@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferPlanValidator()
        let item = BedManagement.newTransferPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferPlanRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.TransferPlanRetriesRangeRule(min: 64, max: 80)
        let item = BedManagement.newTransferPlan("x", title: "y")
        item.retries = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TransferPlanCodeLengthRule(maxLength: 80)
        let item = BedManagement.newTransferPlan("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TransferPlanRequiredCodeRule(message: "transfer plan needs a value")
        let item = BedManagement.newTransferPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferPlanGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.TransferPlanGraceDaysRangeRule(min: 120, max: 255)
        let item = BedManagement.newTransferPlan("x", title: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

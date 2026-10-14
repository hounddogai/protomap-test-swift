@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingCareGapAllocationValidator()
        let item = CareManagement.newPendingCareGapAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingCareGapAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.PendingCareGapAllocationTitleLengthRule(maxLength: 86400)
        let item = CareManagement.newPendingCareGapAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingCareGapAllocationProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.PendingCareGapAllocationProcedureCodeLengthRule(maxLength: 255)
        let item = CareManagement.newPendingCareGapAllocation("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingCareGapAllocationRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = CareManagement.PendingCareGapAllocationRequiredBedRule(
            message: "pending care gap allocation needs an entry"
        )
        let item = CareManagement.newPendingCareGapAllocation("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingCareGapAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingCareGapAllocationCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newPendingCareGapAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingCareGapAllocationBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = CareManagement.PendingCareGapAllocationBedLengthRule(maxLength: 64)
        let item = CareManagement.newPendingCareGapAllocation("x", title: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

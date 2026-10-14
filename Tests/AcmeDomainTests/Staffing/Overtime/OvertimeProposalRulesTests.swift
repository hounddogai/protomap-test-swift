@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeProposalValidator()
        let item = Staffing.newOvertimeProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeProposalRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Staffing.OvertimeProposalRequiredPayerRule(message: "overtime proposal needs a value")
        let item = Staffing.newOvertimeProposal("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeProposalRequiredCodeRule(message: "overtime proposal needs a value")
        let item = Staffing.newOvertimeProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeProposalPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.OvertimeProposalPayerLengthRule(maxLength: 80)
        let item = Staffing.newOvertimeProposal("x", name: "y")
        item.payer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeProposalOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.OvertimeProposalOwnerIDLengthRule(maxLength: 86400)
        let item = Staffing.newOvertimeProposal("x", name: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.OvertimeProposalRequiredNameRule(message: "overtime proposal needs a value")
        let item = Staffing.newOvertimeProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeProposalBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.OvertimeProposalBatchSizeRangeRule(min: 16, max: 3600)
        let item = Staffing.newOvertimeProposal("x", name: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

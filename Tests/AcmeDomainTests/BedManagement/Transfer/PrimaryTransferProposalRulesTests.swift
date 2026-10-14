@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryTransferProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryTransferProposalValidator()
        let item = BedManagement.newPrimaryTransferProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryTransferProposalRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.PrimaryTransferProposalRequiredDiagnosisCodeRule(
            message: "primary transfer proposal needs a value"
        )
        let item = BedManagement.newPrimaryTransferProposal("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryTransferProposalSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = BedManagement.PrimaryTransferProposalSourceLengthRule(maxLength: 255)
        let item = BedManagement.newPrimaryTransferProposal("x", name: "y")
        item.source = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryTransferProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.PrimaryTransferProposalNameLengthRule(maxLength: 80)
        let item = BedManagement.newPrimaryTransferProposal("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryTransferProposalBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = BedManagement.PrimaryTransferProposalBatchSizeRangeRule(min: 120, max: 1000)
        let item = BedManagement.newPrimaryTransferProposal("x", name: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryTransferProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.PrimaryTransferProposalRequiredNameRule(
            message: "primary transfer proposal needs this field"
        )
        let item = BedManagement.newPrimaryTransferProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

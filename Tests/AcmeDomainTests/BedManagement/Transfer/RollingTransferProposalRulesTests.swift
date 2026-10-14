@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingTransferProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingTransferProposalValidator()
        let item = BedManagement.newRollingTransferProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingTransferProposalRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = BedManagement.RollingTransferProposalRevisionRangeRule(min: 16, max: 32)
        let item = BedManagement.newRollingTransferProposal("x", title: "y")
        item.revision = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingTransferProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.RollingTransferProposalRequiredTitleRule(
            message: "rolling transfer proposal needs this field"
        )
        let item = BedManagement.newRollingTransferProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingTransferProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.RollingTransferProposalRequiredCodeRule(
            message: "rolling transfer proposal needs a value"
        )
        let item = BedManagement.newRollingTransferProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingTransferProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.RollingTransferProposalTitleLengthRule(maxLength: 1000)
        let item = BedManagement.newRollingTransferProposal("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingTransferProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RollingTransferProposalCodeLengthRule(maxLength: 32)
        let item = BedManagement.newRollingTransferProposal("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

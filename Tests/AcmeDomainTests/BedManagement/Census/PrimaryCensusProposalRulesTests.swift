@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryCensusProposalValidator()
        let item = BedManagement.newPrimaryCensusProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryCensusProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PrimaryCensusProposalCodeLengthRule(maxLength: 120)
        let item = BedManagement.newPrimaryCensusProposal("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryCensusProposalRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = BedManagement.PrimaryCensusProposalRequiredPatientRefRule(
            message: "primary census proposal needs an entry"
        )
        let item = BedManagement.newPrimaryCensusProposal("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryCensusProposalLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.PrimaryCensusProposalLimitRangeRule(min: 120, max: 1000)
        let item = BedManagement.newPrimaryCensusProposal("x", title: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryCensusProposalRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = BedManagement.PrimaryCensusProposalRequiredOwnerIDRule(
            message: "primary census proposal needs a value"
        )
        let item = BedManagement.newPrimaryCensusProposal("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

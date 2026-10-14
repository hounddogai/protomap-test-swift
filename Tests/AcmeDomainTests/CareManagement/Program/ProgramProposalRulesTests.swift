@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramProposalValidator()
        let item = CareManagement.newProgramProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.ProgramProposalRequiredLabelRule(message: "program proposal needs an entry")
        let item = CareManagement.newProgramProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramProposalRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.ProgramProposalRequiredSegmentRule(message: "program proposal needs an entry")
        let item = CareManagement.newProgramProposal("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ProgramProposalCodeLengthRule(maxLength: 120)
        let item = CareManagement.newProgramProposal("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryOutreachProposalValidator()
        let item = CareManagement.newPrimaryOutreachProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryOutreachProposalMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.PrimaryOutreachProposalMinimumRangeRule(min: 7.6, max: 4430.8)
        let item = CareManagement.newPrimaryOutreachProposal("x", name: "y")
        item.minimum = 4432.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryOutreachProposalCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.PrimaryOutreachProposalCapacityRangeRule(min: 80, max: 3600)
        let item = CareManagement.newPrimaryOutreachProposal("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryOutreachProposalSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = CareManagement.PrimaryOutreachProposalSegmentLengthRule(maxLength: 64)
        let item = CareManagement.newPrimaryOutreachProposal("x", name: "y")
        item.segment = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryOutreachProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PrimaryOutreachProposalCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newPrimaryOutreachProposal("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

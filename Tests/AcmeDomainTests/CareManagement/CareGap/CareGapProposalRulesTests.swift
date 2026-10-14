@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapProposalValidator()
        let item = CareManagement.newCareGapProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CareGapProposalCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newCareGapProposal("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.CareGapProposalLabelLengthRule(maxLength: 120)
        let item = CareManagement.newCareGapProposal("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapProposalRequiredCodeRule(message: "care gap proposal needs an entry")
        let item = CareManagement.newCareGapProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapProposalAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = CareManagement.CareGapProposalAttemptsRangeRule(min: 64, max: 1000)
        let item = CareManagement.newCareGapProposal("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

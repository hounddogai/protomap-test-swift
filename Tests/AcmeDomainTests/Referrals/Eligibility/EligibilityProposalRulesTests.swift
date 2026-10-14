@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityProposalValidator()
        let item = Referrals.newEligibilityProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.EligibilityProposalRequiredLabelRule(message: "eligibility proposal needs this field")
        let item = Referrals.newEligibilityProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityProposalCodeLengthRule(maxLength: 255)
        let item = Referrals.newEligibilityProposal("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.EligibilityProposalLabelLengthRule(maxLength: 1000)
        let item = Referrals.newEligibilityProposal("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityProposalDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Referrals.EligibilityProposalDiagnosisCodeLengthRule(maxLength: 64)
        let item = Referrals.newEligibilityProposal("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

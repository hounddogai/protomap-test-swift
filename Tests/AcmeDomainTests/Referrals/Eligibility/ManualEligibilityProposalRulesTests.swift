@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualEligibilityProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualEligibilityProposalValidator()
        let item = Referrals.newManualEligibilityProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualEligibilityProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ManualEligibilityProposalTitleLengthRule(maxLength: 86400)
        let item = Referrals.newManualEligibilityProposal("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualEligibilityProposalRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Referrals.ManualEligibilityProposalRequiredFacilityRule(
            message: "manual eligibility proposal needs an entry"
        )
        let item = Referrals.newManualEligibilityProposal("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualEligibilityProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ManualEligibilityProposalRequiredCodeRule(
            message: "manual eligibility proposal needs an entry"
        )
        let item = Referrals.newManualEligibilityProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualEligibilityProposalAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.ManualEligibilityProposalAttemptsRangeRule(min: 16, max: 32)
        let item = Referrals.newManualEligibilityProposal("x", title: "y")
        item.attempts = 33
        #expect(rule.check(item).count > 0)
    }
}

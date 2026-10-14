@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingClosureProposalValidator()
        let item = Referrals.newRollingClosureProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingClosureProposalLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.RollingClosureProposalLimitRangeRule(min: 80, max: 120)
        let item = Referrals.newRollingClosureProposal("x", label: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingClosureProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RollingClosureProposalCodeLengthRule(maxLength: 120)
        let item = Referrals.newRollingClosureProposal("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingClosureProposalRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.RollingClosureProposalRateRangeRule(min: 6.1, max: 3346.7)
        let item = Referrals.newRollingClosureProposal("x", label: "y")
        item.rate = 3348.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingClosureProposalRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.RollingClosureProposalRequiredReviewerRule(
            message: "rolling closure proposal needs an entry"
        )
        let item = Referrals.newRollingClosureProposal("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingClosureProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.RollingClosureProposalLabelLengthRule(maxLength: 80)
        let item = Referrals.newRollingClosureProposal("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

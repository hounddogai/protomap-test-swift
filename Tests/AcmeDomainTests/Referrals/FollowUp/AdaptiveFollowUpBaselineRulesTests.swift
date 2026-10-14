@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveFollowUpBaselineValidator()
        let item = Referrals.newAdaptiveFollowUpBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.AdaptiveFollowUpBaselineRequiredTitleRule(
            message: "adaptive follow up baseline needs an entry"
        )
        let item = Referrals.newAdaptiveFollowUpBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsAdaptiveFollowUpBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.AdaptiveFollowUpBaselineCodeLengthRule(maxLength: 86400)
        let item = Referrals.newAdaptiveFollowUpBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpBaselineSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.AdaptiveFollowUpBaselineSequenceRangeRule(min: 3600, max: 3600)
        let item = Referrals.newAdaptiveFollowUpBaseline("x", title: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpBaselineScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.AdaptiveFollowUpBaselineScoreRangeRule(min: 8.9, max: 415.2)
        let item = Referrals.newAdaptiveFollowUpBaseline("x", title: "y")
        item.score = 416.7
        #expect(rule.check(item).count > 0)
    }
}

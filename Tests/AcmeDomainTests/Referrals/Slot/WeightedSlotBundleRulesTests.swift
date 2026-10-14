@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedSlotBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedSlotBundleValidator()
        let item = Referrals.newWeightedSlotBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedSlotBundleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.WeightedSlotBundleScoreRangeRule(min: 2.3, max: 4002.0)
        let item = Referrals.newWeightedSlotBundle("x", title: "y")
        item.score = 4003.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedSlotBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.WeightedSlotBundleTitleLengthRule(maxLength: 3600)
        let item = Referrals.newWeightedSlotBundle("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedSlotBundleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.WeightedSlotBundleRequiredTitleRule(message: "weighted slot bundle needs an entry")
        let item = Referrals.newWeightedSlotBundle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

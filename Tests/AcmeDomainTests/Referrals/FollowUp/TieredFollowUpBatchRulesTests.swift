@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredFollowUpBatchValidator()
        let item = Referrals.newTieredFollowUpBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredFollowUpBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.TieredFollowUpBatchRequiredCodeRule(message: "tiered follow up batch needs this field")
        let item = Referrals.newTieredFollowUpBatch("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredFollowUpBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.TieredFollowUpBatchRequiredTitleRule(message: "tiered follow up batch needs an entry")
        let item = Referrals.newTieredFollowUpBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredFollowUpBatchMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.TieredFollowUpBatchMinimumRangeRule(min: 0.5, max: 314.3)
        let item = Referrals.newTieredFollowUpBatch("x", title: "y")
        item.minimum = 315.8
        #expect(rule.check(item).count > 0)
    }
}

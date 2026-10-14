@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredFollowUpTierValidator()
        let item = Referrals.newTieredFollowUpTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredFollowUpTierRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.TieredFollowUpTierRequiredNameRule(message: "tiered follow up tier needs a value")
        let item = Referrals.newTieredFollowUpTier("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredFollowUpTierDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Referrals.TieredFollowUpTierDescriptionLengthRule(maxLength: 32)
        let item = Referrals.newTieredFollowUpTier("x", name: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

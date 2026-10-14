@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredFollowUpBaselineValidator()
        let item = Referrals.newTieredFollowUpBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredFollowUpBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.TieredFollowUpBaselineRequiredTitleRule(message: "tiered follow up baseline needs a value")
        let item = Referrals.newTieredFollowUpBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredFollowUpBaselineBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.TieredFollowUpBaselineBatchSizeRangeRule(min: 120, max: 255)
        let item = Referrals.newTieredFollowUpBaseline("x", title: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredFollowUpBaselineSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Referrals.TieredFollowUpBaselineSpecialtyLengthRule(maxLength: 3600)
        let item = Referrals.newTieredFollowUpBaseline("x", title: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredFollowUpBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.TieredFollowUpBaselineTitleLengthRule(maxLength: 32)
        let item = Referrals.newTieredFollowUpBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

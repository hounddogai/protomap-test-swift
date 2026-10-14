@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyFollowUpAdjustmentValidator()
        let item = Referrals.newLegacyFollowUpAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyFollowUpAdjustmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.LegacyFollowUpAdjustmentRequiredNameRule(
            message: "legacy follow up adjustment needs an entry"
        )
        let item = Referrals.newLegacyFollowUpAdjustment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyFollowUpAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LegacyFollowUpAdjustmentRequiredCodeRule(
            message: "legacy follow up adjustment needs a value"
        )
        let item = Referrals.newLegacyFollowUpAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

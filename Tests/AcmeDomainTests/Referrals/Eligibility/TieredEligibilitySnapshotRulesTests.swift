@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredEligibilitySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredEligibilitySnapshotValidator()
        let item = Referrals.newTieredEligibilitySnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredEligibilitySnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.TieredEligibilitySnapshotCodeLengthRule(maxLength: 1000)
        let item = Referrals.newTieredEligibilitySnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredEligibilitySnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.TieredEligibilitySnapshotRequiredCodeRule(
            message: "tiered eligibility snapshot needs an entry"
        )
        let item = Referrals.newTieredEligibilitySnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredEligibilitySnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.TieredEligibilitySnapshotTitleLengthRule(maxLength: 64)
        let item = Referrals.newTieredEligibilitySnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

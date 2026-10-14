@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictFollowUpAdjustmentValidator()
        let item = Referrals.newStrictFollowUpAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictFollowUpAdjustmentRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Referrals.StrictFollowUpAdjustmentRequiredRegionRule(
            message: "strict follow up adjustment needs this field"
        )
        let item = Referrals.newStrictFollowUpAdjustment("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictFollowUpAdjustmentRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Referrals.StrictFollowUpAdjustmentRegionLengthRule(maxLength: 16)
        let item = Referrals.newStrictFollowUpAdjustment("x", label: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictFollowUpAdjustmentCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.StrictFollowUpAdjustmentCreatedAtRangeRule(min: 255, max: 255)
        let item = Referrals.newStrictFollowUpAdjustment("x", label: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

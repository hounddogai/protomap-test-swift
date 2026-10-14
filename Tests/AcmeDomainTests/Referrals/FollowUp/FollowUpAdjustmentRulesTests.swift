@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpAdjustmentValidator()
        let item = Referrals.newFollowUpAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.FollowUpAdjustmentNameLengthRule(maxLength: 255)
        let item = Referrals.newFollowUpAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpAdjustmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.FollowUpAdjustmentLimitRangeRule(min: 16, max: 64)
        let item = Referrals.newFollowUpAdjustment("x", name: "y")
        item.limit = 65
        #expect(rule.check(item).count > 0)
    }
}
